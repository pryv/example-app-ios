//
//  ConnectionViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

class ConnectionViewController: UIViewController {
    @IBOutlet private weak var endpointLabel: UILabel!
    
    private let utils = Utils()
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            endpointLabel.text = "API endpoint: \n" + (connection?.getApiEndpoint() ?? "not found")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func callBatch(_ sender: Any) {
        // TODO: create table view with alerts for api calls and submit api() request
    }
    
    @IBAction func getEvents(_ sender: Any) {
        // TODO: create table view to show the events
    }

    @IBAction func createEventFromFile(_ sender: Any) {
        // TODO: open the file selector + event details + show event
    }
}
