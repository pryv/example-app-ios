//
//  ViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
//import PryvApiSwiftKit // TODO: add this import, install the cocoapod library and remove all the files in folder PryvApiSwiftKit

class ViewController: UIViewController {
    
    @IBOutlet private weak var authButton: UIButton!
    private let utils = Utils()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func authenticate(_ sender: Any) {
        // MARK: - set up the auth request with the service and the request payload
        let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
        let authPayload = """
            {
                "requestingAppId": "pryv-interview-exercise",
                "requestedPermissions": [
                    {
                        "streamId": "fitbit",
                        "defaultName": "Fitbit",
                        "level": "read"
                    }
                ]
            }
        """
        
        // MARK: - ask for auth url and load it in the web view to allow the user to login
        if let authUrl = service.setUpAuth(authPayload: authPayload, stateChangedCallback: stateChangedCallback) {
            let vc = self.storyboard?.instantiateViewController(identifier: "webVC") as! WebViewController
            vc.authUrl = authUrl
            self.navigationController?.pushViewController(vc, animated: false)
        } else { print("problem encountered when setting up the authentication") }
    }
    
    /// Callback function to execute when the state of the login from the authenticate function changes
    /// - Parameter authResult: the result of the auth request
    private func stateChangedCallback(authResult: AuthResult) {
        switch authResult.state {
        case .need_signin: // do nothing if still needs to sign in
            return
            
        case .accepted: // show the token and go back to the main view if successfully logged in
            if let endpoint = authResult.endpoint {
                print("The endpoint is \(endpoint)")
                
                self.authButton.isHidden = true
                let token = utils.extractTokenAndEndpoint(apiEndpoint: endpoint)?.token ?? "" 
                let alert = UIAlertController(title: "Request accepted", message: "The token is \(token)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        case .refused: // notify the user that he can still try again if he did not accept to login
            print("The authentication has been refused")
            
            let alert = UIAlertController(title: "Request cancelled", message: "You cancelled the token request. Please, try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}


