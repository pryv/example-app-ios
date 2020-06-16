//
//  UIAlertController+textDidChangeOnLoginAlert.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 16.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit

extension UIAlertController {
    /// Assert the two fields corresponding to username and password are not empty to enable the `OK` button
    @objc func textDidChangeOnLoginAlert() {
        if let username = textFields?[0].text, let password = textFields?[1].text, let action = actions.last {
            action.isEnabled = username.count > 0 && password.count > 0
        }
    }
}
