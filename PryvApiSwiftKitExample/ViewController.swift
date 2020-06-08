//
//  ViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

class ViewController: UIViewController {
    @IBOutlet private weak var serviceInfoUrlField: UITextField!
    @IBOutlet private weak var authDetailsLabel: UILabel!
    
    private let defaultServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let utils = Utils()
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
        let pryvServiceInfoUrl = serviceInfoUrlField.text != nil && serviceInfoUrlField.text != "" ? serviceInfoUrlField.text : defaultServiceInfoUrl
        let service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl!)
        
        if let authUrl = service.setUpAuth(authPayload: authPayload, stateChangedCallback: stateChangedCallback) {
            let vc = self.storyboard?.instantiateViewController(identifier: "webVC") as! WebViewController
            vc.service = service
            vc.authUrl = authUrl
            
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            let alert = UIAlertController(title: "Invalid URL", message: "Please, type a valid service info URL", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            }))
            self.present(alert, animated: true, completion: nil)
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
                self.serviceInfoUrlField.isHidden = true
                self.authDetailsLabel.text = "API endpoint: \n" + endpoint
                
                let token = utils.extractTokenAndEndpoint(apiEndpoint: endpoint)?.token ?? "" 
                let alert = UIAlertController(title: "Request accepted", message: "The token is \(token)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
                
                self.showIfClientValid(endpoint: endpoint, token: token)
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
    
    private func showIfClientValid(endpoint: String, token: String) {
        let string = endpoint.hasSuffix("/") ? (endpoint + "access-info") : (endpoint + "/access-info")
        let url = URL(string: string)
        var request = URLRequest(url: url!)
        request.addValue(token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let loginResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: loginResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when parsing the response") ; return }
            
            if let _ = dictionary["token"] as? String {
                print("Client is valid")
            } else {
                print("Client error")
            }
        }
        task.resume()
    }
    
}


