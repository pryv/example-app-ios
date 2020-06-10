//
//  GetEventsTableViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

class GetEventsTableViewController: UITableViewController {
    
    private var events = [Event]()
    
    var connection: Connection? {
        didSet {
            let request = [
                [
                    "method": "events.get",
                    "params": []
                ]
            ]
            guard let events = connection!.api(APICalls: request) else { return } // FIXME: empty as type error in request body
            events.forEach({ self.events.append($0) })
            
            loadViewIfNeeded()
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "event", for: indexPath)
        
        let event = events[indexPath.row]
        let streamIds = event["streamIds"] as? [String]
        cell.textLabel?.text = streamIds?.joined(separator: ", ")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]
        let streamIds = event["streamIds"] as! [String]
        let content = event["content"] as! Int // TODO: generic content type
        let type = event["type"] as! String
        let message = "The \(streamIds.joined(separator: ", ")) is \(content) \(type)."
        
        let alert = UIAlertController(title: "Event", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }

}
