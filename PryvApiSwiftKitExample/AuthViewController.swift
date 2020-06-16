//
//  WebViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import WebKit
import PryvApiSwiftKit

/// A simple view controller with a web view for the auth request 
class AuthViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!
    var service: Service?
    
    var authUrl: String? {
        didSet {
            loadViewIfNeeded()
            webView.load(URLRequest(url: URL(string: authUrl!)!))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        service?.interruptAuth()
    }
}
