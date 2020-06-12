//
//  GetEventsTableViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

/// Request the last 20 events from the connection and show them in a `UITableView`
class GetEventsTableViewController: UITableViewController {
    
    private var events = [Event]()
    private let utils = Utils()
    private let appUtils = AppUtils()
    
    var connection: Connection? {
        didSet {
            let request = [
                [
                    "method": "events.get",
                    "params": [String: Any]()
                ]
            ]
            guard let events = connection!.api(APICalls: request) else { return }
            events.forEach({ self.events.append($0) })

            loadViewIfNeeded()
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        self.tableView.accessibilityIdentifier = "getEventsTable"
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "event", for: indexPath)
        
        let event = events[indexPath.row]
        if let streamIds = event["streamIds"] as? [String] {
            cell.textLabel?.text = streamIds.joined(separator: ", ")
        }
        if let error = event["message"] as? String {
            cell.textLabel?.text = "Error: \(error)"
        }
        
        cell.accessibilityIdentifier = "eventCell\(indexPath.row)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]
        
        var message: String?
        if let _ = event["streamIds"] as? [String] {
            message = appUtils.eventToString(event)
        } else {
            message = "This event has an error: \(event["message"] ?? "")"
        }
        
        let alert = UIAlertController(title: "Event details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }

}
