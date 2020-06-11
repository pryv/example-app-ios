//
//  ConnectionViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit
import SwiftKeychainWrapper
import FileBrowser

class ConnectionViewController: UIViewController {
    @IBOutlet private weak var endpointLabel: UILabel!
    
    private let utils = Utils()
    private let key = "app-swift-example-endpoint"
    
    var permissions = [Json]()
    private var contributePermissions: [String]?
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            endpointLabel.text = "API endpoint: \n" + (connection?.getApiEndpoint() ?? "not found")
        }
    }
    
    override func viewDidLoad() {
        self.contributePermissions = permissions.filter({$0["level"] as! String == "contribute"}).map({$0["streamId"] as? String ?? ""})
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(back))
    }
    
    @objc func back() {
        if !KeychainWrapper.standard.removeObject(forKey: key) { print("Problem encountered when deleting the current key for endpoint") }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func callBatch(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(identifier: "callBatchTVC") as! CreateBatchTableViewController
        vc.connection = connection
        vc.permissions = contributePermissions ?? []
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func getEvents(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(identifier: "getEventsVC") as! GetEventsTableViewController
        vc.connection = connection
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func createEventFromFile(_ sender: Any) {
        let alert = UIAlertController().newEventAlert(title: "New event", message: "Please, describe your event here. \nNote: only stream ids \(String(describing: contributePermissions ?? [])) will be sent to the server") { (_, params) in
            
            let path = Bundle.main.resourceURL!
            let fileBrowser = FileBrowser(initialPath: path)
            self.present(fileBrowser, animated: true, completion: nil)
            
            fileBrowser.didSelectFile = { (file: FBFile) -> Void in
                let eventWithFile = self.connection?.createEventWithFile(event: params, filePath: file.filePath.absoluteString, mimeType: file.type.rawValue)
                
                if let result = eventWithFile {
                    let text = (result.compactMap({ (key, value) -> String in
                        return "\(key):\(value)"
                    }) as Array).joined(separator: ", \n")
                    
                    let vc = self.storyboard?.instantiateViewController(identifier: "textVC") as! TextViewController
                    vc.text = text
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}
