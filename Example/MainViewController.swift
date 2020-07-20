//
//  ViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvSwiftKit
import TAK

/// View corresponding to the service info, where the can select the service info he wants to connect to, login and open `ConnectionViewController`
class MainViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    private let serviceInfoUrls = ["https://reg.pryv.me/service/info", "https://open2.pryv.io/reg/service/info"] // Add more urls, but take care to add its corresponding SSL certificate to the project
    private let utils = Utils()
    private let appId = "app-swift-example"
    // master token permissions
    private let permissions: [Json] = [[
        "streamId": "*",
        "level": "manage"
    ]]
    private var service: Service!
    private var tak: TAK?
    private var storage: SecureStorage?
    private var pryvServiceInfoUrl: String?
    
    @IBOutlet private weak var authButton: UIButton!
    @IBOutlet private weak var serviceInfoUrlPicker: UIPickerView!
    
    override func viewWillAppear(_ animated: Bool) {
        if let apiEndpoint: String = try? storage?.read(key: "apiEndpoint") {
            openConnection(apiEndpoint: apiEndpoint, animated: false)
        }
    }
    
    override func viewDidLoad() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let loginButton = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(authenticate))
        loginButton.accessibilityIdentifier = "loginButton"
        self.navigationItem.rightBarButtonItem = loginButton
        
        serviceInfoUrlPicker.delegate = self
        serviceInfoUrlPicker.dataSource = self
    }
    
    /// Asks for auth url and load it in the web view to allow the user to login
    /// - Parameter sender: the button to clic on to trigger this action
    @objc func authenticate() {
        let row = serviceInfoUrlPicker.selectedRow(inComponent: 0)
        let pryvServiceInfoUrl = serviceInfoUrls[row]
        
        service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl, session: TakTlsSessionManager.sharedInstance)
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
            self.present(UIAlertController().errorAlert(title: "Please, select a valid service info URL", delay: 2), animated: true, completion: nil)
        }
    }
    
    /// Callback function to execute when the state of the login from the authenticate function changes
    /// - Parameter authResult: the result of the auth request
    private func stateChangedCallback(authResult: AuthResult) {
        switch authResult.state {
        case .need_signin: // do nothing if still needs to sign in
            return
            
        case .accepted: // show the token and go back to the main view if successfully logged in
            if let endpoint = authResult.apiEndpoint {
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
    
    /// Opens a `ConnectionViewController`
    /// - Parameters:
    ///   - apiEndpoint: the api endpoint received from the auth request
    ///   - animated: whether the change of view controller is animated or not (`true` by default)
    private func openConnection(apiEndpoint: String, animated: Bool = true) {
        let connection = Connection(apiEndpoint: apiEndpoint, session: TakTlsSessionManager.sharedInstance)
        
        connection.api(APICalls: [APICall]()).then { _ in
            try? self.storage?.write(key: "apiEndpoint", value: apiEndpoint)
            
            let vc = self.storyboard?.instantiateViewController(identifier: "connectionTBC") as! ConnectionTabBarViewController
            vc.connection = connection
            vc.appId = self.appId
            vc.storage = self.storage
            self.navigationController?.pushViewController(vc, animated: animated)
        }.catch { error in
            self.navigationController?.popViewController(animated: true)
            let alert = UIAlertController().errorAlert(title: "No certificate found for \(apiEndpoint)", delay: 5.0)
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - TAK functions
    
    /// Get the tak object from the AppDelegate and store it as attribute
    /// - Parameter tak
    func passData(tak: TAK?) {
        self.tak = tak
        self.storage = try? tak?.getSecureStorage(storageName: "app-ios-swift-example-secure-storage")
    }
    
    // MARK: - UIPickerViewDelegate
    
    /// Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /// The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) ->Int {
        return serviceInfoUrls.count
    }
    
    /// The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.adjustsFontSizeToFitWidth = true
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = serviceInfoUrls[row]

        return pickerLabel!
    }
}


