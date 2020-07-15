//
//  AppDelegate.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import KeychainSwift
import HealthKit
import PryvSwiftKit
import CoreLocation
import Promises

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    private let appId = "app-swift-example"
    private let keychain = KeychainSwift()
    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    private var anchor = HKQueryAnchor.init(fromValue: 0)
    var connection: Connection? {
        didSet {
            if connection != nil {
                if UserDefaults.standard.object(forKey: "Anchor") != nil {
                    let data = UserDefaults.standard.object(forKey: "Anchor") as! Data
                    anchor = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)!
                }
                
                configureHealthKit()
            }
        }
    }
    
    /* From iOS14+, we will be able to read Health Record as well by adding for example
    `HealthKitStream(type: HKObjectType.clinicalType(forIdentifier: .allergyRecord)!, frequency: .weekly)`
    to this list */
    private let healthKitStreams: [HealthKitStream] = [
        HealthKitStream(type: HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!),
        HealthKitStream(type: HKObjectType.quantityType(forIdentifier: .bodyMass)!, frequency: .immediate),
        HealthKitStream(type: HKObjectType.quantityType(forIdentifier: .height)!, frequency: .immediate),
        HealthKitStream(type: HKObjectType.characteristicType(forIdentifier: .wheelchairUse)!),
        HealthKitStream(type: HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!, frequency: .immediate),
        HealthKitStream(type: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, frequency: .immediate)
    ]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureLocation()
        
        guard HKHealthStore.isHealthDataAvailable() else { return true }
        
        let read = Set(healthKitStreams.map{$0.type})
        let write = PryvStream(streamId: "bodyMass", type: "mass/kg").hkSampleType()!
        healthStore.requestAuthorization(toShare: [write], read: read) { success, error in
            if !success {
                print("Error when requesting authorization for HK data: \(String(describing: error?.localizedDescription))")
            }
        }
        
        let dynamicStreams = healthKitStreams.filter({ $0.needsBackgroundDelivery() })
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
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - location manager
    
    /// Configures the location tracking parameters
    private func configureLocation() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Checks the result of asking for location authorization
    /// - Parameters:
    ///   - manager: location managaer
    ///   - status: the status of the authorization request
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            /* `.startUpdatingLocation()` will track the position with accuracy of `kCLLocationAccuracyKilometer`
             Uncomment this line and comment the line above to have frequent location notifications */
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
    
    // MARK: - HealthKit synchronization
    
    /// Configures the health kit data sync. with Pryv
    private func configureHealthKit() {
        let streamIds = healthKitStreams.map({ $0.pryvStreamId() })
        createStreams(with: streamIds, in: connection)
        
        var staticStreams = healthKitStreams
        staticStreams.removeAll(where: { $0.needsBackgroundDelivery() })
        let dynamicStreams = healthKitStreams.filter({ $0.needsBackgroundDelivery() })
        
        staticStreams.forEach({ staticMonitor(hkDS: $0) })
        dynamicStreams.forEach({ dynamicMonitor(hkDS: $0) })
    }
    
    private func createStreams(with ids: [(parentId: String?, streamId: String)], in connection: Connection?) {
        var apiCalls = [APICall]()
        
        ids.forEach { (parentId, streamId) in
            if let _ = parentId {
                let parentIdCall: APICall = [
                    "method": "streams.create",
                    "params": ["name": parentId!, "id": parentId!]
                ]
                apiCalls.append(parentIdCall)
            }
            
            let streamIdCall: APICall = [
                "method": "streams.create",
                "params": ["parentId": parentId, "name": streamId, "id": streamId]
            ]
            apiCalls.append(streamIdCall)
        }
        
        apiCalls.forEach { apiCall in // do each call separately to avoid any error blocking the other streams creation
            connection?.api(APICalls: [apiCall]).catch { error in
                print("problem encountered when creating HK streams: \(error.localizedDescription)")
            }
        }
    }
    
    /// Monitor static data such as date of birth, once per app launch
    /// Submit the value to Pryv only if any change detected
    private func staticMonitor(hkDS: HealthKitStream) {
        let newContent = hkDS.pryvContentAndType(of: healthStore)
        
        connection?.api(APICalls: [
            [
                "method": "events.get",
                "params": [
                    "streams": [hkDS.pryvStreamId().streamId]
                ]
            ]
        ]).then { json in
            let events = json.first?["events"] as? [Event]
            let storedContent = events?.first?["content"]
            if String(describing: storedContent) != String(describing: newContent) {
                let pryvEvent = hkDS.pryvEvent(of: self.healthStore)
                
                if let data = pryvEvent.attachmentData, let apiEndpoint = self.connection?.getApiEndpoint(){
                    let token = Utils().extractTokenAndEndpoint(from: apiEndpoint)
                    let media = Media(key: "file-\(UUID().uuidString)-\(String(describing: token))", filename: "fhir", data: data, mimeType: "application/json")
                    if let event = pryvEvent.params {
                        self.connection?.createEventWithFormData(event: event as Json, parameters: nil, files: [media]).catch { error in
                            print("Create event with file failed: \(error.localizedDescription)")
                        }
                    }
                } else {
                    if let event = pryvEvent.params {
                        let apiCall: APICall = [
                            "method": "events.create",
                            "params": event
                        ]
                        self.connection?.api(APICalls: [apiCall]).catch { error in
                            print("Api calls failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    /// Monitor dynamic data such as weight periodically
    /// Submit the value to Pryv periodically
    private func dynamicMonitor(hkDS: HealthKitStream) {
        let observerQuery = HKObserverQuery(sampleType: hkDS.type as! HKSampleType, predicate: nil) { _, completionHandler, error in
            defer { completionHandler() }
            if let err = error {
                print("Failed to receive background notification of \(hkDS.type.identifier) change: \(err.localizedDescription)")
                return
            }
            
            #if DEBUG
            print("Received background notification of \(hkDS.type.identifier) change.")
            #endif
            
            let anchoredQuery = HKAnchoredObjectQuery(type: hkDS.type as! HKSampleType, predicate: nil, anchor: self.anchor, limit: HKObjectQueryNoLimit, resultsHandler: self.anchoredQueryResultHandler(hkDS: hkDS))
            anchoredQuery.updateHandler = self.anchoredQueryResultHandler(hkDS: hkDS)
            self.healthStore.execute(anchoredQuery)
        }
        
        healthStore.execute(observerQuery)
    }
    
    private func anchoredQueryResultHandler(hkDS: HealthKitStream) -> ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) {
        return { query, newSamples, deletedSamples, newAnchor, error in
            self.anchoredQueryCompletionHandler(hkDS: hkDS, query: query, newSamples: newSamples, deletedSamples: deletedSamples, newAnchor: newAnchor, error: error)
        }
    }
    
    private func anchoredQueryCompletionHandler(hkDS: HealthKitStream, query: HKAnchoredObjectQuery, newSamples: [HKSample]?, deletedSamples: [HKDeletedObject]?, newAnchor: HKQueryAnchor?, error: Error?) {
        DispatchQueue.main.async {
            if let err = error {
                print("Failed to receive new \(hkDS.type.identifier): \(err.localizedDescription)")
                return
            }
            
            self.anchor = newAnchor!
            let data = try! NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: "Anchor")
            
            if let additions = newSamples {
                let removeDuplicates = Promise<[HKSample]>(on: .global(qos: .background), { (fullfill, reject) in
                    let getEventsWithTagCall: APICall = [
                        "method": "events.get",
                        "params": [
                            "tags": additions.map { sample in String(describing: sample.uuid) }
                        ]
                    ]
                    self.connection?.api(APICalls: [getEventsWithTagCall]).then { results in
                        if let events = results.first?["events"] as? [Event] {
                            let existingSampleIds: [String] = events.flatMap { event in event["tags"] as! [String] }
                            let uniqueAdditions = additions.filter { sample in !existingSampleIds.contains(String(describing: sample.uuid)) }
                            fullfill(uniqueAdditions)
                        }
                    }.catch { error in
                        print("Api call for duplicates failed: \(error.localizedDescription)")
                        reject(error)
                    }
                })
                
                removeDuplicates.then { uniqueAdditions in
                    var apiCalls = [APICall]()
                    
                    for sample in uniqueAdditions {
                        let pryvEvent = hkDS.pryvEvent(from: sample)
                        if let data = pryvEvent.attachmentData, let apiEndpoint = self.connection?.getApiEndpoint(), let event = pryvEvent.params {
                                let token = Utils().extractTokenAndEndpoint(from: apiEndpoint)
                                let media = Media(key: "file-\(UUID().uuidString)-\(String(describing: token))", filename: "fhir", data: data, mimeType: "application/json")
                                self.connection?.createEventWithFormData(event: event as Json, parameters: nil, files: [media]).catch { error in
                                    print("Create event with file failed: \(error.localizedDescription)")
                                }
                        } else {
                            if let event = pryvEvent.params {
                                let apiCall: APICall = [
                                    "method": "events.create",
                                    "params": event
                                ]
                                apiCalls.append(apiCall)
                            }
                        }
                    }

                    self.connection?.api(APICalls: apiCalls).catch { error in
                        print("Api calls for creation of event failed: \(error.localizedDescription)")
                    }
                }
                
                // FIXME
                // Promises are not executed before a new notification is received => duplicated !
            }
            
            if let deletions = deletedSamples, deletions.count > 0 {
                self.deleteHKDeletions(deletions)
            }
        }
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
    
    
}

