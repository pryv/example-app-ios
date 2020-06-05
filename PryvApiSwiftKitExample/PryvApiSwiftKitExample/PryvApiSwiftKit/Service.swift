//
//  Service.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 02.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public class Service {
    private let utils = Utils()
    
    private var timer: Timer?
    
    private var pryvServiceInfoUrl: String
    private var serviceCustomization: [String: Any]
    
    private var pryvServiceInfo: PryvServiceInfo? = nil
    
    private var pollingInfo: (poll: String, poll_ms: Double, callback: (AuthResult) -> ())? {
        didSet {
            DispatchQueue.global(qos: .background).async {
                self.poll(poll: self.pollingInfo!.poll, poll_ms: self.pollingInfo!.poll_ms, stateChangedCallback: self.pollingInfo!.callback)
            }
        }
    }
    
    // MARK: - public library
    
    /// Inits a service with the service info url and no custom element
    /// - Parameter pryvServiceInfoUrl: url point to /service/info of a Pryv platform as: `https://access.{domain}/service/info`
    init(pryvServiceInfoUrl: String) {
        self.pryvServiceInfoUrl = pryvServiceInfoUrl
        self.serviceCustomization = [String: Any]()
    }
    
    /// Inits a service with the service info url and custom elements
    /// - Parameters:
    ///   - pryvServiceInfoUrl: url point to /service/info of a Pryv platform as: `https://access.{domain}/service/info`
    ///   - serviceCustomization: a json formatted dictionary corresponding to the customizations of the service
    init(pryvServiceInfoUrl: String, serviceCustomization: [String: Any]) {
        self.pryvServiceInfoUrl = pryvServiceInfoUrl
        self.serviceCustomization = serviceCustomization
    }
    
    /// Returns service info parameters
    /// # Example #
    /// - name of the platform: `let serviceName = service.info().name`
    /// See `PryvServiceInfo` for details on available properties
    /// - Returns: the fetched service info object, customized if needed, or nil if problem is encountered while fetching
    public func info() -> PryvServiceInfo? {
        pryvServiceInfo = sendServiceInfoRequest()
        customizeService()
        
        return pryvServiceInfo
    }
    
    /// Constructs the API endpoint from this service and the username and token
    /// - Parameters:
    ///   - username
    ///   - token (optionnal)
    /// - Returns: API Endpoint from a username and token and the PryvServiceInfo
    public func apiEndpointFor(username: String, token: String? = nil) -> String? {
        let serviceInfo = pryvServiceInfo ?? info()
        guard let apiEndpoint = serviceInfo?.api.replacingOccurrences(of: "{username}", with: username) else { print("problem encountered when building the service info api") ; return nil}
        
        return utils.buildPryvApiEndPoint(endpoint: apiEndpoint, token: token)
    }
    
    /// Issue a "login call on the Service" return a Connection on success
    /// **Warning !**: the token of the connection will be a "Personal" token that expires
    /// See [the API](https://api.pryv.com/reference-full/#login-user)
    /// - Parameters:
    ///   - username
    ///   - password
    ///   - appId
    /// - Returns: the user's connection to the appId or nil if problem is encountered
    public func login(username: String, password: String, appId: String) -> Connection? {
        var connection: Connection? = nil
        let loginPayload = ["username": username, "password": password, "appId": appId]
        guard let apiEndpoint = apiEndpointFor(username: username) else { return nil }
        
        let token = sendLoginRequest(endpoint: apiEndpoint + "auth/login", payload: loginPayload)
        if let apiEndpoint = self.apiEndpointFor(username: username, token: token) {
           connection = Connection(apiEndpoint: apiEndpoint)
        }
        
        return connection
    }
    
    /// Sends an auth request to the `access` field of the service info and polls the received url
    /// such that the callback function is called when the state of the connection is changed
    /// - Parameters:
    ///   - authPayload: the auth request json formatted string according to [the API reference](https://api.pryv.com/reference/#auth-request)
    ///   - stateChangedCallback: function that will be called as soon as the state of the authentication changes
    /// - Returns: the `authUrl` field from the response to the service info
    ///
    ///  # Use case example
    ///    ```
    ///    let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    ///    let authUrl = service.setupAuth(
    ///      authRequestParams: [see [the API reference](https://api.pryv.com/reference/#auth-request) for the elements],
    ///      stateChangedCallback: callback
    ///    )
    ///    // open a web view with the `authUrl` to let the user login
    ///
    ///    func callback(state: AuthState) {
    ///            switch state {
    ///            case .accepted:
    ///                print("ACCEPTED")
    ///            case .need_signin:
    ///            case .refused:
    ///                print("REFUSED")
    ///            }
    ///    }
    ///    ```
    public func setUpAuth(authPayload: String, stateChangedCallback: @escaping (AuthResult) -> ()) -> String? {
        let serviceInfo = pryvServiceInfo ?? info()
        guard let registerUrl = serviceInfo?.register else { print("problem encountered when getting the register url") ; return nil }
        
        guard let (authUrl, poll, poll_ms) = sendAuthRequest(string: registerUrl + "/access", payload: authPayload) else { print("problem encountered when getting the result for auth request") ; return nil }
        self.pollingInfo = (poll: poll, poll_ms: poll_ms, callback: stateChangedCallback)
        
        return authUrl
    }
    
    /// This function will be implemented later, according to the documentation on [lib-js](https://github.com/pryv/lib-js#pryvbrowser--visual-assets)
    public func assets() {
        // TODO
    }
    
    // MARK: - private helpers functions for the library
    
    /// Customizes the service info parameters
    private func customizeService() {
        if let register = serviceCustomization["register"] as? String { pryvServiceInfo?.register = register }
        if let access = serviceCustomization["access"] as? String { pryvServiceInfo?.access = access }
        if let api = serviceCustomization["api"] as? String { pryvServiceInfo?.api = api }
        if let name = serviceCustomization["name"] as? String { pryvServiceInfo?.name = name }
        if let home = serviceCustomization["home"] as? String { pryvServiceInfo?.home = home }
        if let support = serviceCustomization["support"] as? String { pryvServiceInfo?.support = support }
        if let terms = serviceCustomization["terms"] as? String { pryvServiceInfo?.terms = terms }
        if let eventTypes = serviceCustomization["eventTypes"] as? String { pryvServiceInfo?.eventTypes = eventTypes }
    }
    
    /// Decodes json data into a PryvServiceInfo object
    /// - Parameter json: json encoded data structured as a service info object
    /// - Returns: the PryvServiceInfo object corresponding to the json or nil if problem is encountered
    private func decodeServiceInfo(from json: Data) -> PryvServiceInfo? {
        let decoder = JSONDecoder()
        
        do {
            let service = try decoder.decode(PryvServiceInfo.self, from: json)
            return service
        } catch {
            print("problem encountered when parsing the service info response: " + error.localizedDescription)
            return nil
        }
    }
    
    /// Fetches the service info from the service info url
    /// - Returns: the service info received from the request
    private func sendServiceInfoRequest() -> PryvServiceInfo? {
        guard let url = URL(string: pryvServiceInfoUrl) else { print("problem encountered: cannot access url \(pryvServiceInfoUrl)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [String: Any]())
        
        var result: PryvServiceInfo? = nil
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error, data == nil { print("problem encountered when requesting the service info") ; group.leave() ; return }
            result = self.decodeServiceInfo(from: data!)
            group.leave()
        }
        
        group.enter()
        task.resume()
        group.wait()
        
        return result
    }
    
    /// Sends a login request to the login url from the service info and returns the response token
    /// - Parameters:
    ///   - endpoint: the api endpoint given by the service info
    ///   - payload: the json formatted payload for the request: username, password and app id
    /// - Returns: the token received from the request
    private func sendLoginRequest(endpoint: String, payload: [String: Any]) -> String? {
        guard let url = URL(string: endpoint) else { print("problem encountered: cannot access register url \(endpoint)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        var token: String? = nil
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let _ = error, data == nil { print("problem encountered when requesting login") ; group.leave() ; return }

            guard let loginResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: loginResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when parsing the login response") ; group.leave() ; return }
            
            token = dictionary["token"] as? String
            group.leave()
        }

        group.enter()
        task.resume()
        group.wait()
        
        return token
    }
    
    /// Sends an authentication request to the access url from the service info and returns the `authUrl`, `poll` and `poll_ms` fields
    /// - Parameters:
    ///   - string: the field `register` of the service info concatenated with "/access"
    ///   - payload: the json formatted payload for the request according to [the API reference](https://api.pryv.com/reference/#auth-request)
    /// - Returns: the fields `authUrl`, `poll` and `poll_ms`
    private func sendAuthRequest(string: String, payload: String) -> (String, String, Double)? {
        guard let url = URL(string: string) else { print("problem encountered: cannot access register url \(string)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(payload.utf8)
        
        var result: (String, String, Double)? = nil
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let _ = error, data == nil { print("problem encountered when sending the auth request") ; group.leave() ; return }

            guard let authResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: authResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when decoding the auth response") ; group.leave() ; return }
            
            let authURL = dictionary["authUrl"] as? String
            let poll = dictionary["poll"] as? String
            let poll_rate_ms = dictionary["poll_rate_ms"] as? Double
            
            if let authURL = authURL, let poll = poll, let poll_rate_ms = poll_rate_ms {
                result = (authURL, poll, poll_rate_ms)
            }
            
            group.leave()
        }

        group.enter()
        task.resume()
        group.wait()
        
        return result
    }
    
    /// Sends a polling request to the `poll` field from the auth request and returns the status and, if any, the api endpoint
    /// - Parameters:
    ///   - request: the request containing the poll url
    ///   - completion: closure containing the parsed data, if any, from the response of the request
    /// - Returns: the closure `completion` is called after the function returns to access the fields `status` and `apiEndpoint`
    private func sendPollingRequest(request: URLRequest, completion: @escaping ((String, String?)?) -> ()) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let _ = error, data == nil { print("problem encountered when polling") ; return completion(nil) }

            guard let pollResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: pollResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when decoding the poll response") ; return completion(nil) }
            
            guard let status = dictionary["status"] as? String else { return completion(nil) }
            let pryvApiEndpoint = dictionary["apiEndpoint"] as? String
            
            return completion((status, pryvApiEndpoint))
        }

        task.resume()
    }
    
    /// Sends a request to the polling url and calls the callback function from the setUpAuth function if the state changes
    /// - Parameters:
    ///   - poll: the url for the polling request
    ///   - poll_ms: the rate for the polling
    ///   - stateChangedCallback: callback function to call upon a state change
    private func poll(poll: String, poll_ms: Double, stateChangedCallback: @escaping (AuthResult) -> ()) {
        var currentState: AuthStates = .need_signin
        
        // Library doc: TimeInteval is in seconds, whereas poll_rate_ms is in milliseconds
        self.timer = Timer.scheduledTimer(withTimeInterval: poll_ms * 0.001, repeats: true) { _ in
            var request = URLRequest(url: URL(string: poll)!)
            request.httpMethod = "GET"
            
            self.sendPollingRequest(request: request) { tuple in
                 if let (status, pryvApiEndpoint) = tuple {
                    switch status {
                        
                    case "REFUSED":
                        self.timer?.invalidate()
                        
                        if (currentState != .refused) {
                            currentState = .refused
                            let result = AuthResult(state: currentState, endpoint: nil)
                            DispatchQueue.main.async {
                                stateChangedCallback(result)
                            }
                        }
                        
                    case "NEED_SIGNIN":
                        if (currentState != .need_signin) {
                            currentState = .need_signin
                            let result = AuthResult(state: currentState, endpoint: nil)
                            DispatchQueue.main.async {
                                stateChangedCallback(result)
                            }
                        }
                        
                    case "ACCEPTED":
                        self.timer?.invalidate()
                        guard let pryvApiEndpoint = pryvApiEndpoint else { print("Cannot get field \"apiEndpoint\" from response") ; return }
                        
                        if currentState != .accepted {
                            currentState = .accepted
                            let result = AuthResult(state: currentState, endpoint: pryvApiEndpoint)
                            DispatchQueue.main.async {
                                stateChangedCallback(result)
                            }
                        }
                        
                    default:
                        print("problem encountered when polling: unexpected status")
                    }
                 }
            }
        }
    }

}