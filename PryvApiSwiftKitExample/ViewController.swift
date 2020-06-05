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
    
    private let utils = Utils()
    private let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    private let authPayload = """
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
    
    @IBOutlet private weak var authButton: UIButton!
    
    /// Asks for auth url and load it in the web view to allow the user to login
    /// - Parameter sender: the button to clic on to trigger this action
    @IBAction func authenticate(_ sender: Any) {
        if let authUrl = service.setUpAuth(authPayload: authPayload, stateChangedCallback: stateChangedCallback) {
            let vc = self.storyboard?.instantiateViewController(identifier: "webVC") as! WebViewController
            vc.service = self.service
            vc.authUrl = authUrl
            
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            print("problem encountered when setting up the authentication")
        }
    }
    
    /// Callback function to execute when the state of the login from the authenticate function changes
    /// - Parameter authResult: the result of the auth request
    private func stateChangedCallback(authResult: AuthResult) {
        switch authResult.state {
        case .need_signin: // do nothing if still needs to sign in
            return
            
        case .accepted: // show the token and go back to the main view if successfully logged in
            if let endpoint = authResult.endpoint {
                self.authButton.isHidden = true
                let token = utils.extractTokenAndEndpoint(apiEndpoint: endpoint)?.token ?? "" 
                let alert = UIAlertController(title: "Request accepted", message: "The token is \(token)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        case .refused: // notify the user that he can still try again if he did not accept to login
            let alert = UIAlertController(title: "Request cancelled", message: "You cancelled the token request. Please, try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
            
        case .timeout: // notify the user that he has a fixed time to log in and that the connection timed out
            let alert = UIAlertController(title: "The request timed out", message: "You exceeded the login delay of 1min30s. Please, try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}


