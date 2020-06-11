//
//  TextViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {
    @IBOutlet private weak var textLabel: UILabel!
    
    var text: String? {
        didSet {
            loadViewIfNeeded()
            textLabel.text = text!
        }
    }

}
