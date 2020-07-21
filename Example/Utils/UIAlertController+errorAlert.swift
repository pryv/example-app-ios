//
//  UIAlertController+errorAlert.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 16.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    /// Ephemere alert that appears only for a fixed interval of time
    /// - Parameters:
    ///   - title: the title of the alert
    ///   - delay: the time interval in seconds while the alert is visible
    /// - Returns: the ephemere alert
    func ephemereAlert(title: String, delay: Double) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let deadline = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: deadline) {
          alert.dismiss(animated: true, completion: nil)
        }
        
        return alert
    }
}
