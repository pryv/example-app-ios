//
//  CreateBatchTableViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

/// `UITableView` that can be filled with events by the user.
class CreateBatchTableViewController: UITableViewController {
    private var apiCalls = [(String, APICall)]()
    
    var connection: Connection?
    var permissions = [String]()

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apiCalls.count
    }
    
    /// Adds an event to the `tableView` according to the parameters filled in the `UIAlertController` text fields
    @objc private func addAPICall() {
        let alert = UIAlertController().newEventAlert(title: "Your new event", message: "Only stream ids \(String(describing: permissions)) will be sent to the server") { (name, params) in
            let apiCall: APICall = [
                "method": "events.create",
                "params": params
            ]
            self.apiCalls.append((name, apiCall))
            self.tableView.reloadData()
        }
    }
    
    /// Sends a batch of `event.create` request with all the events in the `tableView`
    @objc private func sendCreationAPICalls() {
        let apiCallsWithoutName = apiCalls.map({$0.1})
        
        var handleResults = [Int: (Event) -> ()]()
        for i in 0..<apiCallsWithoutName.count {
            handleResults[i] = { event in
                print("event \(i + 1): \(String(describing: event))")
            }
        }
        
        let _ = connection?.api(APICalls: apiCallsWithoutName, handleResults: handleResults)
    }
    
}
