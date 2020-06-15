//
//  FactoryViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 15.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit

class FactoryViewController: UIViewController {

    static func makeMainVC(storyboard: UIStoryboard, appId: String) -> MainViewController {
        let mainVC = storyboard.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
        mainVC.appId = appId

        return mainVC
    }

}
