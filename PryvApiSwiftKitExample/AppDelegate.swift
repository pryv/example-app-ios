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
import PryvApiSwiftKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let appId = "app-swift-example"
    private let keychain = KeychainSwift()
    private let healthStore = HKHealthStore()
    var connection: Connection? {
        didSet {
            if connection != nil {
                configureHealthKit()
            }
        }
    }
    private let streams: [HKEvent] = [
        //        HKEvent(type: HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .bodyMass)!, frequency: .immediate),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .height)!, frequency: .immediate),
        //        HKEvent(type: HKObjectType.characteristicType(forIdentifier: .wheelchairUse)!),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!, frequency: .immediate),
        HKEvent(type: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, frequency: .immediate)
    ]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return true }
        
        let healthKitStreams = Set(streams.map{$0.type})
        healthStore.requestAuthorization(toShare: .none, read: healthKitStreams) { _, _ in return }
        
        let dynamicStreams = streams.filter({ $0.needsBackgroundDelivery() })
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
        
        if let apiEndpoint = keychain.get(appId) {
            connection = Connection(apiEndpoint: apiEndpoint)
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
    
    // MARK: - HealthKit synchronization
    
    /// Configures the health kit data sync. with Pryv
    private func configureHealthKit() {
        let streamIds = streams.map({ $0.eventStreamId() })
        createStreams(with: streamIds, in: connection)
        
        
        
        var staticStreams = streams
        staticStreams.removeAll(where: { $0.needsBackgroundDelivery() })
        let dynamicStreams = streams.filter({ $0.needsBackgroundDelivery() })
        
        staticStreams.forEach({ staticMonitor(stream: $0) })
        dynamicStreams.forEach({ dynamicMonitor(stream: $0) })
    }
    
    private func createStreams(with ids: [String], in connection: Connection?) {
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
    
    
}

