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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create events"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAPICall))
        addButton.accessibilityIdentifier = "addEventButton"
        
        let sendButton = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendCreationAPICalls))
        sendButton.accessibilityIdentifier = "sendEventsButton"
        
        self.navigationItem.rightBarButtonItems = [addButton, sendButton]
        
        self.tableView.accessibilityIdentifier = "newEventsTable"
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apiCalls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "apiCall", for: indexPath)
        let (name, apiCall) = apiCalls[indexPath.row]
        let params = apiCall["params"] as? [String: Any]
        let streamId = params?["streamId"] as? String ?? ""
            
        if !streamId.isEmpty { cell.textLabel?.text = name.isEmpty ? "Event \(indexPath.row + 1): \(streamId)" : name }
        else { cell.textLabel?.text = name.isEmpty ? "Event \(indexPath.row + 1)" : name }
        
        cell.accessibilityIdentifier = "newEvent\(indexPath.row)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = apiCalls[indexPath.row].0
        let apiCall = apiCalls[indexPath.row].1
        let params = apiCall["params"] as? Json
        
        let alert = UIAlertController().newEventAlert(editing: true, title: "Edit \(name)", message: "Only stream ids \(String(describing: permissions)) will be sent to the server", name: name, params: params) { (name, params) in
            let apiCall: APICall = [
                "method": "events.create",
                "params": params
            ]
            self.apiCalls[indexPath.row] = (name, apiCall)
            self.tableView.reloadData()
        }
        self.present(alert, animated: true, completion: nil)
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
        
        alert.view.accessibilityIdentifier = "addEventAlert"
        
        self.present(alert, animated: true, completion: nil)
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
        self.navigationController?.popViewController(animated: true)
    }
    
}
