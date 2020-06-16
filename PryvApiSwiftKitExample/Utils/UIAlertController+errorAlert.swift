//
//  UIAlertController+errorAlert.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 16.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit

extension UIAlertController {
    func errorAlert(title: String, delay: Double) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let deadline = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: deadline) {
          alert.dismiss(animated: true, completion: nil)
        }
        
        return alert
    }
}
