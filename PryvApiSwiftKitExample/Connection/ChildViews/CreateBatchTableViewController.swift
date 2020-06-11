//
//  CreateBatchTableViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

class CreateBatchTableViewController: UITableViewController {
    private var apiCalls = [(String, APICall)]()
    
    var connection: Connection?
    var permissions = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create new events"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAPICall))
        addButton.accessibilityIdentifier = "addEventButton"
        
        let submitButton = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitAPICalls))
        submitButton.accessibilityIdentifier = "submitEventsButton"
        
        self.navigationItem.rightBarButtonItems = [addButton, submitButton]
        
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
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = apiCalls[indexPath.row].0
        let apiCall = apiCalls[indexPath.row].1
        let params = apiCall["params"] as? Json
        
        let alert = UIAlertController().newEventAlert(editing: true, title: "Edit \(name)", message: "Note: only stream ids in \(String(describing: permissions)) will be sent to the server", name: name, params: params) { (name, params) in
            let apiCall: APICall = [
                "method": "events.create",
                "params": params
            ]
            self.apiCalls[indexPath.row] = (name, apiCall)
            self.tableView.reloadData()
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func addAPICall() {
        let alert = UIAlertController().newEventAlert(title: "New API call", message: "Please, describe your API call here. \nNote: only stream ids \(String(describing: permissions)) will be sent to the server") { (name, params) in
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
    
    @objc private func submitAPICalls() {
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
