//
//  ViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit
import KeychainSwift

/// View corresponding to the service info, where the can select the service info he wants to connect to, login and open `ConnectionViewController`
class MainViewController: UIViewController {
    
    private let defaultServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let utils = Utils()
    private let appId = "app-swift-example"
    private let permissions: [Json] = [
        [
            "streamId": "weight",
            "defaultName": "Weight",
            "level": "contribute"
        ],
        [
            "streamId": "weight",
            "defaultName": "Weight",
            "level": "read"
        ]
    ]
    private let keychain = KeychainSwift()
    
    @IBOutlet private weak var authButton: UIButton!
    @IBOutlet private weak var serviceInfoUrlField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        if let endpoint = keychain.get(appId) {
            openConnection(apiEndpoint: endpoint, animated: false)
        }
    }
    
    override func viewDidLoad() {
        let loginButton = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(authenticate))
        loginButton.accessibilityIdentifier = "loginButton"
        self.navigationItem.rightBarButtonItem = loginButton
        
        serviceInfoUrlField.text = defaultServiceInfoUrl
    }
    
    /// Asks for the username and password, logs the user in and opens the connection view
    /// - Parameter sender: the button to clic on to trigger this action
    @IBAction func login(_ sender: Any) {
        let pryvServiceInfoUrl = serviceInfoUrlField.text != nil && serviceInfoUrlField.text != "" ? serviceInfoUrlField.text : defaultServiceInfoUrl
        let alert = UIAlertController(title: "Login", message: nil, preferredStyle: .alert)

        let submit = UIAlertAction(title: "OK", style: .default, handler: { _ in
            let username = alert.textFields![0].text ?? ""
            let password = alert.textFields![1].attributedText?.string ?? ""
            let service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl!)
            guard let connection = service.login(username: username, password: password, appId: self.appId, domain: "pryv.me") else {
                self.present(UIAlertController().errorAlert(title: "Incorrect username or password", delay: 2), animated: true, completion: nil)
                return
            }
            self.openConnection(connection: connection)
        })
        submit.isEnabled = false
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in })
        
        alert.addAction(cancel)
        alert.addAction(submit)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "username"
            textField.addTarget(alert, action: #selector(alert.textDidChangeOnLoginAlert), for: .editingChanged)
            textField.accessibilityIdentifier = "usernameField"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "password"
            textField.isSecureTextEntry = true
            textField.addTarget(alert, action: #selector(alert.textDidChangeOnLoginAlert), for: .editingChanged)
            textField.accessibilityIdentifier = "passwordField"
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Asks for auth url and load it in the web view to allow the user to login
    /// - Parameter sender: the button to clic on to trigger this action
    @objc func authenticate() {
        let pryvServiceInfoUrl = serviceInfoUrlField.text != nil && serviceInfoUrlField.text != "" ? serviceInfoUrlField.text : defaultServiceInfoUrl
        let service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl!)
        let authPayload: Json = [
            "requestingAppId": appId,
            "requestedPermissions": permissions,
            "languageCode": "fr"
        ]
        
        if let authUrl = service.setUpAuth(authPayload: authPayload, stateChangedCallback: stateChangedCallback) {
            let vc = self.storyboard?.instantiateViewController(identifier: "webVC") as! AuthViewController
            vc.service = service
            vc.authUrl = authUrl
            
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            self.present(UIAlertController().errorAlert(title: "Please, type a valid service info URL", delay: 2), animated: true, completion: nil)
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
                let token = utils.extractTokenAndEndpoint(apiEndpoint: endpoint)?.token ?? ""
                if !self.isClientValid(endpoint: endpoint, token: token) { return }
                openConnection(apiEndpoint: endpoint)
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
    
    /// Checks whether the client is valid once the user has logged in and accepted the auth request
    /// - Parameters:
    ///   - endpoint: the api endpoint received from the auth request
    ///   - token: the token received from the auth request
    /// - Returns: `true` if valid, i.e. if a connection can be done. `false` otherwise
    private func isClientValid(endpoint: String, token: String) -> Bool {
        var result = false
        
        let string = endpoint.hasSuffix("/") ? (endpoint + "access-info") : (endpoint + "/access-info")
        let url = URL(string: string)
        var request = URLRequest(url: url!)
        request.addValue(token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let loginResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: loginResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when parsing the response") ; group.leave() ; return }
            
            if let _ = dictionary["token"] as? String {
                print("Client is valid")
                result = true
                group.leave()
            } else {
                print("Client error")
                group.leave()
            }
        }
        
        
        group.enter()
        task.resume()
        group.wait()
        
        return result
    }
    
    /// Opens a `ConnectionViewController`
    /// - Parameters:
    ///   - apiEndpoint: the api endpoint received from the auth request
    ///   - animated: whether the change of view controller is animated or not (`true` by default)
    private func openConnection(apiEndpoint: String, animated: Bool = true) {
        keychain.set(apiEndpoint, forKey: appId)
        
        let vc = self.storyboard?.instantiateViewController(identifier: "connectionVC") as! ConnectionViewController
        vc.connection = Connection(apiEndpoint: apiEndpoint)
        vc.contributePermissions = permissions.filter({$0["level"] as! String == "contribute"}).map({$0["streamId"] as? String ?? ""})
        vc.appId = appId
        self.navigationController?.pushViewController(vc, animated: animated)
    }
    
    /// Opens a `ConnectionViewController`
    /// - Parameter connection: the connection received from the login request 
    private func openConnection(connection: Connection) {
        keychain.set(connection.getApiEndpoint(), forKey: appId)
        
        let vc = self.storyboard?.instantiateViewController(identifier: "connectionVC") as! ConnectionViewController
        vc.connection = connection
        vc.contributePermissions = permissions.filter({$0["level"] as! String == "contribute"}).map({$0["streamId"] as? String ?? ""})
        vc.appId = appId
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}


