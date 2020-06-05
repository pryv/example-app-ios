//
//  WebViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!
    
    var authUrl: String? {
        didSet {
            loadViewIfNeeded()
            webView.load(URLRequest(url: URL(string: authUrl!)!))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
