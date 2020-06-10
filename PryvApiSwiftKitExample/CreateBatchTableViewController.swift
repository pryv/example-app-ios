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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create new events"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAPICall))
        let okButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(submitAPICalls))
        self.navigationItem.rightBarButtonItems = [addButton, okButton]
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apiCalls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "apiCall", for: indexPath)
        cell.textLabel?.text = apiCalls[indexPath.row].0
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = apiCalls[indexPath.row].0
        let apiCall = apiCalls[indexPath.row].1
        let params = apiCall["params"] as? Json
        
        let alert = UIAlertController(title: "Edit \(name)", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.text = name
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.text = params?["streamId"] as? String ?? ""
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.text = params?["type"] as? String ?? ""
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.text = String(params?["content"] as? Int ?? 0)
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let apiCall: APICall = [
                "method": "events.create",
                "params": [
                    "streamId": alert.textFields![1].text ?? "",
                    "type": alert.textFields![2].text ?? "",
                    "content": Int(alert.textFields![3].text ?? "0") ?? 0
                ]
            ]
            
            self.apiCalls[indexPath.row] = ((alert.textFields![1].text ?? "", apiCall))
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in self.tableView.reloadData() }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func addAPICall() {
        let alert = UIAlertController(title: "New API call", message: "Please, describe your API call here", preferredStyle: .alert)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name of your new event"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter stream id"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter type"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter content"
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let apiCall: APICall = [
                "method": "events.create",
                "params": [
                    "streamId": alert.textFields![1].text ?? "",
                    "type": alert.textFields![2].text ?? "",
                    "content": Int(alert.textFields![3].text ?? "0") ?? 0
                ]
            ]
            
            self.apiCalls.append((alert.textFields![1].text ?? "", apiCall))
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in self.tableView.reloadData() }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func submitAPICalls() {
        let apiCallsWithoutName = apiCalls.map({$0.1})
        
        var handleResults = [Int: (Event) -> ()]()
        for i in 0..<apiCallsWithoutName.count {
            handleResults[i] = { event in
                print(event["streamId"] ?? "problem encountered when getting the stream id")
            }
        }
        
        let _ = connection?.api(APICalls: apiCallsWithoutName, handleResults: nil) // FIXME: invalid type for request - expected array but found object
        self.navigationController?.popViewController(animated: true)
    }
    
}
