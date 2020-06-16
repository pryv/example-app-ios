//
//  ConnectionViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit
import KeychainSwift
import FileBrowser

/// View corresponding to a user's connection, where he can create events and see the last 20 of them
class ConnectionViewController: UIViewController {
    @IBOutlet private weak var endpointLabel: UILabel!
    
    private let appUtils = AppUtils()
    private let utils = Utils()
    private let keychain = KeychainSwift()
    
    var appId: String?
    var contributePermissions: [String]?
    var serviceName: String?
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            endpointLabel.text = "API endpoint: \n" + (connection?.getApiEndpoint() ?? "not found")
        }
    }
    
    override func viewDidLoad() {
        if let username = utils.extractUsername(apiEndpoint: connection?.getApiEndpoint() ?? ""), let service = serviceName {
            let logoutButton = UIBarButtonItem(title: "\(service) - \(username)", style: .plain, target: self, action: #selector(logout))
            logoutButton.accessibilityIdentifier = "logoutButton"
            self.navigationItem.rightBarButtonItem = logoutButton
        }
        
        navigationItem.hidesBackButton = true
    }
    
    /// Logs the current user out by deleting the saved endpoint in the keychain
    @objc func logout() {
        if let key = appId {
            keychain.delete(key)
        }
        
        let alert = UIAlertController(title: "Log out", message: "Do you want to log out ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in self.navigationController?.popToRootViewController(animated: true) }))
        alert.addAction(UIAlertAction(title: "No", style: .destructive, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Opens the `CreateBatchTableViewController` to create new events
    /// - Parameter sender: the button to `tap()` to trigger this function
    @IBAction func createBatchRequest(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(identifier: "callBatchTVC") as! CreateBatchTableViewController
        vc.connection = connection
        vc.permissions = contributePermissions ?? []
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Opens the `GetEventsTableViewController` to see the last 20 events
    /// - Parameter sender: the button to `tap()` to trigger this function
    @IBAction func getEvents(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(identifier: "getEventsVC") as! GetEventsTableViewController
        vc.connection = connection
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Opens a `UIAlertController` to create a new event from the alert's field: streamId, type and content
    /// When the text fields are filles, opens a file browser to select a file to attach and show the created event in a `TextViewController`
    /// - Parameter sender: the button to `tap()` to trigger this function
    @IBAction func createEventFromFile(_ sender: Any) {
        let alert = UIAlertController().newEventAlert(title: "Your new event", message: "Only stream ids \(String(describing: contributePermissions ?? [])) will be sent to the server") { (_, params) in
            
            let path = Bundle.main.resourceURL!
            let fileBrowser = FileBrowser(initialPath: path)
            self.present(fileBrowser, animated: true, completion: nil)
            
            fileBrowser.didSelectFile = { (file: FBFile) -> Void in
                let eventWithFile = self.connection?.createEventWithFile(event: params, filePath: file.filePath.absoluteString, mimeType: file.type.rawValue)
                
                if let result = eventWithFile {
                    let text = self.appUtils.eventToString(result)
                    let vc = self.storyboard?.instantiateViewController(identifier: "textVC") as! TextViewController
                    vc.text = text
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}
