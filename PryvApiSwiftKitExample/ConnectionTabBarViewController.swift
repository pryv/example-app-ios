//
//  ConnectionTabBarViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit
import KeychainSwift
import CoreLocation
import HealthKit

class ConnectionTabBarViewController: UITabBarController, CLLocationManagerDelegate {
    private let keychain = KeychainSwift()
    private let utils = Utils()
    
    private let locationManager = CLLocationManager()
    
    private let healthStore = HKHealthStore()
    private let streams: [HKEvent] = [
//        HKEvent(type: HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .bodyMass)!, frequency: .immediate),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .height)!, frequency: .immediate),
//        HKEvent(type: HKObjectType.characteristicType(forIdentifier: .wheelchairUse)!),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!, frequency: .immediate)
    ]
    
    var service: Service?
    var connection: Connection?
    var appId: String?
    
    override func viewWillAppear(_ animated: Bool) {
        let listVC = viewControllers?[0] as? ConnectionListTableViewController
        listVC?.connection = connection
        listVC?.appId = appId
        
        let mapVC = viewControllers?[1] as? ConnectionMapViewController
        mapVC?.connection = connection
        
        navigationController?.navigationBar.accessibilityIdentifier = "connectionNavBar"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureLocation()
        configureHealthKit()
    }
    
    /// Configures the health kit data sync. with the app
    private func configureHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthKitStreams = Set(streams.map{$0.type})
        healthStore.requestAuthorization(toShare: .none, read: healthKitStreams) { _, _ in return }
        
        let dynamicStreams = streams.filter({ $0.needsBackgroundDelivery() })
        
        var staticStreams = streams
        staticStreams.removeAll(where: { $0.needsBackgroundDelivery() })
        
        for stream in dynamicStreams {
            healthStore.enableBackgroundDelivery(for: stream.type, frequency: stream.frequency!, withCompletion: { succeeded, error in
                if let err = error, !succeeded {
                    print("Failed to enable background delivery of \(stream.type.identifier) changes: \(err)")
                } else {
                    #if DEBUG
                    print("Enabled background delivery of \(stream.type.identifier) changes")
                    #endif
                }
            })
        }
        
        let streamIds = streams.map({ $0.eventStreamId() })
        createStreams(with: streamIds)
        monitorHealthData(staticStreams: staticStreams, dynamicStreams: dynamicStreams)
    }
    
    private func createStreams(with ids: [String]) {
        var apiCalls = [APICall]()
        ids.forEach { id in
            let apiCall: APICall = [
                "method": "streams.create",
                "params": ["name": id, "id": id]
            ]
            apiCalls.append(apiCall)
        }
        connection?.api(APICalls: apiCalls).catch { error in
            print("problem encountered when creating HK streams: \(error.localizedDescription)")
        }
    }
    
    /// Monitor healthkit data and send it to Pryv
    /// - Parameter staticStreams: the streams of data to monitor statically, i.e. only once per app install
    /// - Parameter dynamicStreams: the streams of data to monitor dynamically, i.e. periodically in background
    private func monitorHealthData(staticStreams: [HKEvent], dynamicStreams: [HKEvent]) {
        staticStreams.forEach({ staticMonitor(stream: $0) })
        dynamicStreams.forEach({ dynamicMonitor(stream: $0) })
    }
    
    /// Monitor static data such as date of birth, once per app launch
    /// Submit the value to Pryv only if any change detected
    private func staticMonitor(stream: HKEvent) {
        let newContent = stream.eventContent(of: healthStore)
        
        connection?.api(APICalls: [
            [
                "method": "events.get",
                "params": [
                    "streams": [stream.eventStreamId()]
                ]
            ]
        ]).then { json in
            let events = json.first?["events"] as? [Event]
            let storedContent = events?.first?["content"]
            if String(describing: storedContent) != String(describing: newContent) {
                self.connection?.api(APICalls: [stream.event(of: self.healthStore)]).catch { error in
                    print("Api calls failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Monitor dynamic data such as weight periodically
    /// Submit the value to Pryv periodically
    private func dynamicMonitor(stream: HKEvent) { 
        let observerQuery = HKObserverQuery(sampleType: stream.type as! HKSampleType, predicate: nil) { _, completionHandler, error in
            defer { completionHandler() }
            if let err = error {
                print("Failed to receive background notification of \(stream.type.identifier) change: \(err)")
                return
            }
            
            var anchor = HKQueryAnchor.init(fromValue: 0)
            if UserDefaults.standard.object(forKey: "Anchor") != nil {
                let data = UserDefaults.standard.object(forKey: "Anchor") as! Data
                anchor = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)!
            }
            
            let anchoredQuery = HKAnchoredObjectQuery(type: stream.type as! HKSampleType, predicate: nil, anchor: anchor, limit: HKObjectQueryNoLimit) { (_, newSamples, deletedSamples, newAnchor, error) in
                DispatchQueue.main.async {
                    if let err = error {
                        print("Failed to receive new \(stream.type.identifier): \(err)")
                        return
                    }
                    
                    anchor = newAnchor!
                    let data = try! NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any, requiringSecureCoding: true)
                    UserDefaults.standard.set(data, forKey: "Anchor")
                    
                    if let additions = newSamples, additions.count > 0 {
                        var apiCalls = [APICall]()
                        for sample in additions {
                            let apiCall = stream.event(from: sample)
                            apiCalls.append(apiCall)
                        }
                        
                        self.connection?.api(APICalls: apiCalls).catch { error in
                            print("Api calls for addition failed: \(error.localizedDescription)")
                        }
                    }
                    
                    if let deletions = deletedSamples, deletions.count > 0 {
                        self.deleteHKDeletions(deletions)
                    }
                }
            }
            
            self.healthStore.execute(anchoredQuery)
        }
        
        healthStore.execute(observerQuery)
    }
    
    /// Delete Pryv events if deleted in HK
    /// - Parameter deletions: the deleted streams from HK
    private func deleteHKDeletions(_ deletions: [HKDeletedObject]) {
        let tags = deletions.map { String(describing: $0.uuid) }
        self.connection?.api(APICalls: [
            [
                "method": "events.get",
                "params": [
                    "tags": tags
                ]
            ]
        ]).then { json in
            guard let events = json.first?["events"] as? [Event] else { return }
            let ids = events.map { $0["id"] as? String }.filter { $0 != nil }.map { $0! }
            var apiCalls = [APICall]()
            
            for id in ids {
                apiCalls.append([
                    "method": "events.delete",
                    "params": [
                        "id": id
                    ]
                ])
            }
            
            self.connection?.api(APICalls: apiCalls).catch { error in
                print("Api calls for deletion failed: \(error.localizedDescription)")
            }
        }.catch { error in
            print("Api calls to get deleted uuid failed: \(error.localizedDescription)")
        }
    }
    
    /// Configures the location tracking parameters
    private func configureLocation() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Configures the UI for the view with the log out button and the title
    private func configureUI() {
        let logoutButton = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(logout))
        logoutButton.accessibilityIdentifier = "logoutButton"
        navigationItem.leftBarButtonItem = logoutButton
        navigationItem.hidesBackButton = true
        
        service?.info().then { serviceInfo in
            self.navigationItem.title = serviceInfo.name
            self.connection?.username().then { username in
                self.navigationItem.title! += "-"
                self.navigationItem.title! += username
            }
        }.catch { _ in
            self.navigationItem.title = "Last events"
        }
        navigationItem.largeTitleDisplayMode = .automatic
    }
    
    /// If confirmed, logs the current user out by deleting the saved endpoint in the keychain
    @objc private func logout() {
        let alert = UIAlertController(title: nil, message: "Do you want to log out ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { _ in
            if let key = self.appId {
                self.keychain.delete(key)
            }
            self.navigationController?.popToRootViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - location manager
    
    /// Checks the result of asking for location authorization
    /// - Parameters:
    ///   - manager: location managaer
    ///   - status: the status of the authorization request
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            /* `.startUpdatingLocation()` will track the position with accuracy of `kCLLocationAccuracyKilometer`
             Let this line uncommented to have frequent location notifications */
//            locationManager.startUpdatingLocation()
            
            /* `.startMonitoringSignificantLocationChanges()` will have a precision of 500m, but will not send more than 1 change in 5 minutes.
             Uncomment this line and comment the line below to avoid using too much power */
             locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    /// Manage newly received location updates
    /// - Parameters:
    ///   - manager: location manager
    ///   - locations: array with the latest location(s)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var apiCalls = [APICall]()
        for location in locations {
            let params: Json = [
                "streamId": "diary",
                "type": "position/wgs84",
                "content": [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "altitude": location.altitude,
                    "horizontalAccuracy": location.horizontalAccuracy,
                    "verticalAccuracy": location.verticalAccuracy,
                    "speed": location.speed
                ]
            ]
            
            let apiCall: APICall = [
                "method": "events.create",
                "params": params
            ]
            apiCalls.append(apiCall)
        }
        
        print("Sending location...")
        connection?.api(APICalls: apiCalls).catch { error in
            print("Problem encountered when sending position to the server: \(error.localizedDescription)")
        }
    }
    
    /// Manage newly received location updates in case of an error
    /// - Parameters:
    ///   - manager: location manager
    ///   - locations: array with the latest location(s)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Problem encountered when tracking position: \(error)")
    }
    
}

