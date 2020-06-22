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
    var service: Service?
    var apiEndpoint: String?
    var appId: String?
    var permissions: [String]?
    
    override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let listVC = self.storyboard?.instantiateViewController(identifier: "connectionListVC") as! ConnectionListTableViewController
        listVC.serviceName = service?.info()?.name
        if let _ = apiEndpoint {
            listVC.connection = Connection(apiEndpoint: apiEndpoint!)
        }
        listVC.contributePermissions = permissions
        listVC.appId = appId
        return [listVC] // TODO: add map
    }

}
