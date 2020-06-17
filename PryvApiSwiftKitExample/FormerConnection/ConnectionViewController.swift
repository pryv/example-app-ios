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
class FormerConnectionViewController: UIViewController {
    private let appUtils = AppUtils()
    private let utils = Utils()
    private let keychain = KeychainSwift()
    
    var appId: String?
    var contributePermissions: [String]?
    var serviceName: String?
    var connection: Connection?
    
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
    
    // TODO: use it for add attachment
    /// Opens a `UIAlertController` to create a new event from the alert's field: streamId, type and content
    /// When the text fields are filles, opens a file browser to select a file to attach and show the created event in a `TextViewController`
    /// - Parameter sender: the button to `tap()` to trigger this function
    func createEventFromFile(_ sender: Any) {
        let alert = UIAlertController().newEventAlert(title: "Your new event", message: "Only stream ids \(String(describing: contributePermissions ?? [])) will be sent to the server") { (_, params) in
            
            let path = Bundle.main.resourceURL!
            let fileBrowser = FileBrowser(initialPath: path)
            self.present(fileBrowser, animated: true, completion: nil)
            
            fileBrowser.didSelectFile = { (file: FBFile) -> Void in
                let eventWithFile = self.connection?.createEventWithFile(event: params, filePath: file.filePath.absoluteString, mimeType: file.type.rawValue)
                
                if let result = eventWithFile {
                    let text = self.appUtils.eventToString(result)
                    // TODO: show attachment ?
                }
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}
