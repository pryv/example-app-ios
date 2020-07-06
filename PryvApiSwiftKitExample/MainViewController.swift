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
    // master token permissions
    private let permissions: [Json] = [[
        "streamId": "*",
        "level": "manage"
    ]]
    private let keychain = KeychainSwift()
    private var service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    
    @IBOutlet private weak var authButton: UIButton!
    @IBOutlet private weak var serviceInfoUrlField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        if let endpoint = keychain.get(appId) {
            openConnection(apiEndpoint: endpoint, animated: false)
        }
    }
    
    override func viewDidLoad() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let loginButton = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(authenticate))
        loginButton.accessibilityIdentifier = "loginButton"
        self.navigationItem.rightBarButtonItem = loginButton
        
        serviceInfoUrlField.text = defaultServiceInfoUrl
    }
    
    /// Asks for auth url and load it in the web view to allow the user to login
    /// - Parameter sender: the button to clic on to trigger this action
    @objc func authenticate() {
        let pryvServiceInfoUrl = serviceInfoUrlField.text != nil && serviceInfoUrlField.text != "" ? serviceInfoUrlField.text : defaultServiceInfoUrl
        service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl!)
        let authPayload: Json = [
            "requestingAppId": appId,
            "requestedPermissions": permissions,
            "languageCode": "fr"
        ]
        
        service.setUpAuth(authSettings: authPayload, stateChangedCallback: stateChangedCallback).then { authUrl in
            let vc = self.storyboard?.instantiateViewController(identifier: "webVC") as! AuthViewController
            vc.service = self.service
            vc.authUrl = authUrl
            
            self.navigationController?.pushViewController(vc, animated: false)
        }.catch { _ in
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
                let token = utils.extractTokenAndEndpoint(from: endpoint)?.token ?? ""
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
        let connection = Connection(apiEndpoint: apiEndpoint)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.connection = connection
        
        let vc = self.storyboard?.instantiateViewController(identifier: "connectionTBC") as! ConnectionTabBarViewController
        vc.service = service
        vc.connection = connection
        vc.appId = appId
        self.navigationController?.pushViewController(vc, animated: animated)
    }
    
}


