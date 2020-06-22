//
//  ConnectionViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import PryvApiSwiftKit

class ConnectionViewController: BarPagerTabStripViewController {
    var service: Service
    var apiEndpoint: String
    var appId: String
    var permissions: [String]
    
    init(service: Service, apiEndpoint: String, appId: String, permissions: [String]) {
        self.service = service
        self.apiEndpoint = apiEndpoint
        self.appId = appId
        self.permissions = permissions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let listVC = self.storyboard?.instantiateViewController(identifier: "connectionListVC") as! ConnectionListTableViewController
        listVC.serviceName = service.info()?.name
        listVC.connection = Connection(apiEndpoint: apiEndpoint)
        listVC.contributePermissions = permissions
        listVC.appId = appId
        return [listVC] // TODO: add map
    }

}
