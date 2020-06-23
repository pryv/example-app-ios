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
import FileBrowser

/// A custom cell to show the details of an event
class EventTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var attachmentImageView: UIImageView!
    @IBOutlet private weak var streamIdLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var attachmentLabel: UILabel!
    @IBOutlet weak var addAttachmentButton: UIButton!
    
    @IBOutlet private weak var typeStackView: UIStackView!
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var attachmentStackView: UIStackView!
    
    var data: (Connection?, Event)? {
        didSet {
            let (connection, event) = data!
            guard let eventId = event["id"] as? String, let streamId = event["streamId"] as? String, let type = event["type"] as? String, let content = event["content"] else { return }
            streamIdLabel.text = streamId
            
            if type.contains("picture") { // If the event has a picture attached, show it.
                attachmentImageView.isHidden = false
                attachmentImageView.image = UIImage(data: (connection?.getImagePreview(eventId: eventId))!)
            } else { // Otherwise, show the type of content, the actual content and the name of the file attached
                typeStackView.isHidden = false
                typeLabel.text = type
                
                let contentString = String(describing: content)
                if !contentString.contains("null") {
                    contentStackView.isHidden = false
                    contentLabel.text = contentString.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "=", with: ": ").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: ";", with: "\n").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "\n}", with: "") // formatting the json string to make it readable
                }
                
                if let attachments = event["attachments"] as? [Json], let fileName = attachments.last?["fileName"] as? String {
                    attachmentStackView.isHidden = false
                    attachmentLabel.text = fileName
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        attachmentImageView.image = nil
        streamIdLabel.text = nil
        typeLabel.text = nil
        contentLabel.text = nil
        attachmentLabel.text = nil

        attachmentImageView.isHidden = true
        attachmentStackView.isHidden = true
        contentStackView.isHidden = true
        typeStackView.isHidden = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        attachmentImageView.accessibilityIdentifier = "attachmentImageView"
        attachmentLabel.accessibilityIdentifier = "attachmentLabel"
        streamIdLabel.accessibilityIdentifier = "streamIdLabel"
        typeLabel.accessibilityIdentifier = "typeLabel"
        contentLabel.accessibilityIdentifier = "contentLabel"
        addAttachmentButton.accessibilityIdentifier = "addAttachmentButton"
    }
    
}

class ConnectionListTableViewController: UITableViewController {
    private let keychain = KeychainSwift()
    private var refreshEnabled = true // set to true when a new event is added or an event is modified, avoids loading the events if no change
    private var events = [Event]()
    
    var appId: String?
    var contributePermissions: [String]?
    var serviceName: String?
    var connection: Connection? {
        didSet {
            getEvents()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addEventButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addEvent))
        addEventButton.accessibilityIdentifier = "addEventButton"
        tabBarController?.navigationItem.rightBarButtonItem = addEventButton
        
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 100;
        tableView.rowHeight = UITableView.automaticDimension;
        tableView.accessibilityIdentifier = "eventsTableView"
        
        refreshControl?.addTarget(self, action: #selector(getEvents), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = false
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as? EventTableViewCell else { return UITableViewCell() }
        
        let event = events[indexPath.row]
        if let error = event["message"] as? String { print("Error for event at row \(indexPath.row): \(error)") ; return UITableViewCell() }
        cell.data = (connection, event)
        cell.addAttachmentButton.tag = indexPath.row
        cell.addAttachmentButton.addTarget(self, action: #selector(addAttachment), for: .touchUpInside)
        
        cell.accessibilityIdentifier = "eventCell\(indexPath.row)"

        return cell
    }
    
    // MARK: - Table view interactions
    
    /// Creates a new event from the fields in a `UIAlertController` and sends a `event.create` request within a callbatch
    @objc private func addEvent() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Simple event", style: .default) { _ in
            let message: String? = self.contributePermissions == nil ? nil : "Note: only stream ids in \(String(describing: self.contributePermissions!)) will be accepted."
            let alert = UIAlertController().newEventAlert(title: "Create an event", message: message) { params in
                let apiCall: APICall = [
                    "method": "events.create",
                    "params": params
                ]
    
                let handleResults: [Int: (Event) -> ()] = [0: { event in
                    print("new event: \(String(describing: event))")
                }]
    
                let _ = self.connection?.api(APICalls: [apiCall], handleResults: handleResults)
    
                self.refreshEnabled = true
            }
            self.present(alert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Event with attachment", style: .default) { _ in
            let message: String? = self.contributePermissions == nil ? nil : "Note: only stream ids in \(String(describing: self.contributePermissions!)) will be accepted."
            let alert = UIAlertController().newEventAlert(title: "Create an event", message: message) { params in
                let path = Bundle.main.resourceURL!
                let fileBrowser = FileBrowser(initialPath: path)
                fileBrowser.view.accessibilityIdentifier = "fileBrowserCreate"
                self.present(fileBrowser, animated: true, completion: nil)

                fileBrowser.didSelectFile = { (file: FBFile) -> Void in
                    let _ = self.connection?.createEventWithFile(event: params, filePath: file.filePath.absoluteString, mimeType: file.type.rawValue)
                    self.refreshEnabled = true
                }
            }

            self.present(alert, animated: true, completion: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    /// Adds an attachment to an existing event in the `tableView`
    /// - Parameter sender: the button that trigger this action
    @objc private func addAttachment(_ sender: UIButton) {
        let event = events[sender.tag]
        guard let eventId = event["id"] as? String else { return }
        
        let path = Bundle.main.resourceURL!
        let fileBrowser = FileBrowser(initialPath: path)
        fileBrowser.view.accessibilityIdentifier = "fileBrowserAdd"
        self.present(fileBrowser, animated: true, completion: nil)

        fileBrowser.didSelectFile = { (file: FBFile) -> Void in
            let _ = self.connection?.addFileToEvent(eventId: eventId, filePath: file.filePath.absoluteString, mimeType: file.type.rawValue)
            self.refreshEnabled = true
        }
    }
    
    /// Updates the list of events shown (only if an event was added)
    /// # Note
    ///     Here, we use a batch call, not the streamed version. Indeed, we are only taking the last 20 events, which does not require streaming.
    @objc private func getEvents() {
        if refreshEnabled {
            refreshEnabled = false
            
            let request = [
                [
                    "method": "events.get",
                    "params": Json()
                ]
            ]
            if let result = connection!.api(APICalls: request) { self.events = result }

            loadViewIfNeeded()
            self.tableView.reloadData()
        }
        self.refreshControl?.endRefreshing()
    }

}
