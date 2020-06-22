//
//  ConnectionTabBarViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

class ConnectionTabBarViewController: UITabBarController {
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

        // Do any additional setup after loading the view.
    }

}
