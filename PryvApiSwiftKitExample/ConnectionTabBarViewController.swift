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

class ConnectionTabBarViewController: UITabBarController, CLLocationManagerDelegate {
    private let keychain = KeychainSwift()
    private let utils = Utils()
    private let locationManager = CLLocationManager()
    
    var serviceName: String?
    var connection: Connection?
    var permissions: [String]?
    var appId: String?
    
    override func viewWillAppear(_ animated: Bool) {
        let listVC = self.storyboard?.instantiateViewController(identifier: "connectionListVC") as! ConnectionTableViewController
        listVC.serviceName = serviceName
        listVC.connection = connection
        listVC.contributePermissions = permissions
        listVC.appId = appId
        
        viewControllers = [listVC]
        navigationController?.navigationBar.accessibilityIdentifier = "connectionNavBar"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logoutButton = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(logout))
        logoutButton.accessibilityIdentifier = "logoutButton"
        navigationItem.leftBarButtonItem = logoutButton
        navigationItem.hidesBackButton = true
        
        if let username = utils.extractUsername(apiEndpoint: connection?.getApiEndpoint() ?? ""), let service = serviceName {
            navigationItem.title = "\(service) - \(username)"
        } else {
            navigationItem.title = "Last events"
        }
        navigationItem.largeTitleDisplayMode = .automatic
        
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestAlwaysAuthorization()
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
    
    // MARK: - location tracking
    
    /// Checks the result of asking for location authorization
    /// - Parameters:
    ///   - manager: location managaer
    ///   - status: the status of the authorization request
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            //            locationManager.startMonitoringSignificantLocationChanges()
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
        guard let _ = connection?.api(APICalls: apiCalls) else { print("Problem encountered when sending position to the server") ; return }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Problem encountered when tracking position: \(error)")
    }
    
}
