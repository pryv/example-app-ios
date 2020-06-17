//
//  ConnectionTableViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 17.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import KeychainSwift
import PryvApiSwiftKit

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var attachmentImageView: UIImageView! // TODO: show image
    @IBOutlet private weak var streamIdLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var attachmentLabel: UILabel!
    
    @IBOutlet private weak var attachmentTitleLabel: UILabel!
    @IBOutlet private weak var contentTitleLabel: UILabel!
    
    var streamId: String? {
        didSet {
            streamIdLabel.text = streamId!
        }
    }
    
    var type: String? {
        didSet {
            typeLabel.text = type!
        }
    }
    
    var content: String? {
        didSet {
            if content != "nil" { // TODO: check if really == "nil" when image
                contentLabel.text = content!
            } else {
                contentLabel.isHidden = true
                contentTitleLabel.isHidden = true
            }
        }
    }
    
    var fileName: String? {
        didSet {
            attachmentLabel.isHidden = false
            attachmentTitleLabel.isHidden = false
            attachmentLabel.text = fileName!
        }
    }
    
}

class ConnectionTableViewController: UITableViewController {
    private let appUtils = AppUtils()
    private let utils = Utils()
    private let keychain = KeychainSwift()
    
    private var events = [Event]()
    
    var appId: String?
    var contributePermissions: [String]?
    var serviceName: String?
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
        if let username = utils.extractUsername(apiEndpoint: connection?.getApiEndpoint() ?? ""), let service = serviceName {
            let logoutButton = UIBarButtonItem(title: "\(service) - \(username)", style: .plain, target: self, action: #selector(logout))
            logoutButton.accessibilityIdentifier = "logoutButton"
            self.navigationItem.rightBarButtonItem = logoutButton
        }
        
        navigationItem.hidesBackButton = true
        tableView.allowsSelection = false
        
        tableView.accessibilityIdentifier = "eventsTableView"
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as? EventTableViewCell else { return UITableViewCell() }
        
        let event = events[indexPath.row]
        if let error = event["message"] as? String { print("Error for event at row \(indexPath.row): \(error)") ; return UITableViewCell() }
        
        guard let streamId = event["streamId"] as? String, let type = event["type"] as? String, let content = event["content"] else { return UITableViewCell() }
        cell.streamId = streamId
        cell.type = type
        cell.content = String(describing: content)
        
        // TODO: how to get the file if image and show ??
        
        if let attachments = event["attachments"] as? [Json], let fileName = attachments[0]["fileName"] as? String { // TODO: note takes the first one ?
            cell.fileName = fileName
        }
        
        cell.accessibilityIdentifier = "eventCell\(indexPath.row)"

        return cell
    }
    
    // MARK: - Interactions with the user, apart from the table view
    
    /// If confirmed, logs the current user out by deleting the saved endpoint in the keychain
    @objc private func logout() {
        let alert = UIAlertController(title: nil, message: "Do you want to log out ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            if let key = self.appId {
                self.keychain.delete(key)
            }
            self.navigationController?.popToRootViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }

}
