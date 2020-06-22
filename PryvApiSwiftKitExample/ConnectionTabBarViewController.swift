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

class ConnectionTabBarViewController: UITabBarController {
    private let keychain = KeychainSwift()
    
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

}
