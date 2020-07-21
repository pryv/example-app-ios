//
//  ConnectionTabBarViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvSwiftKit
import CoreLocation
import TAK

class ConnectionTabBarViewController: UITabBarController, CLLocationManagerDelegate {
    private let utils = Utils()
    
    var service: Service?
    var appId: String?
    var connection: Connection? {
        didSet {
            self.service = connection?.getService()
        }
    }
    var storage: SecureStorage?
    var tak: TAK?
    
    override func viewWillAppear(_ animated: Bool) {
        let listVC = viewControllers?[0] as? ConnectionListTableViewController
        listVC?.appId = appId
        listVC?.connection = connection
        listVC?.tak = tak
        
        let mapVC = viewControllers?[1] as? ConnectionMapViewController
        mapVC?.connection = connection
        
        navigationController?.navigationBar.accessibilityIdentifier = "connectionNavBar"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    /// Configures the UI for the view with the log out button and the title
    private func configureUI() {
        service?.info().then { serviceInfo in self.navigationItem.title = serviceInfo.name }
            .catch { _ in self.navigationItem.title = "Last events" }
        navigationItem.largeTitleDisplayMode = .automatic
        
        self.connection?.username()
        .then { username in
            let userButton = UIBarButtonItem(title: username, style: .plain, target: self, action: #selector(self.openUserMenu))
            userButton.accessibilityIdentifier = "userButton"
            self.navigationItem.rightBarButtonItem = userButton
            self.navigationItem.hidesBackButton = true
        }
    }
    
    /// Opens a user menu to go to the settings or log out
    @objc private func openUserMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Manage privacy settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { success in
                    if !success {
                        print("Error when opening the settings bundle")
                    }
                })
            }
        })
        
        alert.addAction(UIAlertAction(title: "Manage health data", style: .default) { _ in
            if let healthUrl = URL(string: "x-apple-health://"), UIApplication.shared.canOpenURL(healthUrl) {
                UIApplication.shared.open(healthUrl, completionHandler: { success in
                    if !success {
                        print("Error when opening the Health app")
                    }
                })
            }
        })
        
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive) { _ in
            let alert = UIAlertController(title: nil, message: "Do you want to log out ?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { _ in
                try? self.storage?.deleteEntry(key: "apiEndpoint")
                self.navigationController?.popToRootViewController(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
            self.present(alert, animated: true, completion: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

