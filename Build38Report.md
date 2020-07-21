# Integration of BUILD38 into app-ios-swift-example

## Table of contents
- [T.A.K Client SDK Integration](#tak-client-sdk-integration)
- [T.A.K Client SDK Usage](#tak-client-sdk-usage)
  - [T.A.K. Initialization](#tak-initialization)
  - [Features used](#features-used)
  - [Implementation of the features](#implementation-of-the-features)
    - [Secure storage](#secure-storage)
    - [Secure channel](#secure-channel)
      - [Secure Certificate Pinning](#secure-certificate-pinning)
    - [Jailbreak detection](#jailbreak-detection)
    - [Signature generation](#signature-generation)

## T.A.K Client SDK Integration

For the client DSK integration, one follows the steps listed in [TAK doc](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#xcode_integration2) for "XCode - Swift API" in the "Integration" part, i.e. add the frameworks and the license to the project.  

Note that these additions were only done locally. Consequently, neither TAK.framework and TakTls.framework nor the license can be found on GitHub, in this repo. One needs to import its own license: 

-  in XCode, `file > Add files to Example ...`, select your tak license and add it to the Example and the ExampleUITests targets
- drag and drop the two folders `TAK-Client/iOS/Swift/libs/TAK.framework` and `TAK-Client/iOS/Swift/libs/TakTls.framework` in  `Example/Frameworks` folder in XCode project
- add the framework to the Example and ExampleUITests targets
- in `Example > General > Frameworks, Libraries, and Embedded Content`,  chose `embed & sign` for both of the frameworks
- in `Example > Build Phases > Link Binary with Libraries`, chose `Optional` status for both of the frameworks
- in `ExampleUITests > Build Phases > Link Binary with Libraries`, chose `Optional` status for both of the frameworks

## T.A.K Client SDK Usage

### T.A.K. Initialization

Before using any feature provided by T.A.K., one needs to set up the SDK. 

In the `SceneDelegate.swift` file, add the code snippet given in the documentation for the initialization. To use the TAK feature, the `tak` object needs to be passed to every view controller in the application from the `AppDelegate.swift`.

This is the result code: 

```swift
guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let tak = try? TAK(licenseFileName: "license")
        if let isRegistered = try? tak?.isRegistered(), !isRegistered { // register at first launch
            do {
                let registrationResponse = try tak!.register(userHash: nil)
                if (registrationResponse.isLicenseAboutToExpire) {
                    print("Warning: TAK license is about to expire.")
                }
            } catch {
                print("Error: T.A.K register failed: \(error.localizedDescription)")
            }
        } else {
            do { 
                let checkIntegrityResponse = try tak!.checkIntegrity() // check integrity from second launch on
                if (checkIntegrityResponse.isLicenseAboutToExpire) {
                    print("Warning: T.A.K checkIntegrity was successful: TAK license is about to expire.")
                } else {
                    print("Success: T.A.K check integrity was successful")
                }
            } catch {
                print("Error: Problem occurred when checking integrity of T.A.K: \(error.localizedDescription)")
            }
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
        mainVC.passData(tak: tak) // pass the tak object to the view controllers
        let initialViewController = UINavigationController(rootViewController: mainVC)
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
}
```

When launching the application, the first time one opens the application, it should successfully register and the second time, it should successfully check the integrity.

### Features used

According to the "Non-Functional features" part in the documentation, the idea is: 

> - Storing some necessary user credential (e.g. authentication token) in the [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).
> - Protecting some necessary app credential (e.g. API token) using the [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector).
> - Enabling client authentication in the backend and using the [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect to it.

Consequently, one will use the following features: 

- [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage) to store the user's authentication token and API endpoint.
- [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect for
  - Requesting events;
  - Creating events;
  - Any other HTTP request in the application.

- [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector) will only be used for encrypting the SSL certificates in secure channels. Otherwise, one does not require it, as no huge storage (>1MB) is stored on the device, nor any asset. 
- Jailbreak detection will be used in the T.A.K. initialization part, to query the jailbreak status of the current device.
- Signature Generation will be used to verify the events and streams created by any user via the iOS application. The events created in the application will be displayed with a "verified" tag.

The following features will not be integrated in the app: 

- [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify) as jailbreak check will be implemented in the application;
- App re-packaging protection as it is not yet available in iOS;
- HealthCheck API as it is not a DevOps application. 

### Implementation of the features

#### Secure storage

The only object stored on the device is the API endpoint through the use of keychain. Now, instead of using iOS keychain, one can use Build38's secure storage. 

There are two view controllers that need secure storage: 

- `MainViewController`: As it is responsible for launching the authentication request and passing the result, i.e. the API endpoint, to the `ConnectionTabViewController`, it needs to store the API endpoint got from the connection in a secure storage and pass this storage to `ConnectionTabViewController`.
- `ConnectionTabViewController`: Instead of getting the raw value of the API endpoint, it will get the storage that contains it. From this, it can create a connection bound to the stored API endpoint and pass this object to `ConnectionListTableViewController` and `ConnectionMapViewController`. As `ConnectionListTableViewController` and `ConnectionMapViewController` do not handle any API endpoint nor token directly, they do not need access to the storage. 

To securely implement writes and reads for the user's credentials, one follows the code snippets given in the [documentation](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage):

```swift
let storage = try tak.getSecureStorage(storageName: "app-example-storage")

// Write apiEndpoint to secure storage
try storage.write(key: "apiEndpoint", value: "https://ckcqduq2q0003xnpv7tlx63o3@chuangzi.pryv.me/")

// Read apiEndpoint from secure storage using the key "apiEndpoint"
let apiEndpoint: String = try storage.read(key: "apiEndpoint")
```

#### Secure channel

To integrate secure channel, as `lib-swift` uses `Alamofire` for the HTTP requests, one could use the code snippet provided in the documentation section "Integration with Alamofire". However, this snippet uses an older version of Alamofire than `lib-swift`. Therefore, one should modify it a bit to match the new classes in Alamofire (see `TakTlsSessionManager.swift`): 

```swift
class TakTlsSessionManager: Session {

    /// Use this property to get an Alamofire SessionManager which is configured to use TAK TLS implementation.
    static let sharedInstance: TakTlsSessionManager = TakTlsSessionManager()

    init() {
        // Set up T.A.K
        let tak = try! TAK(licenseFileName: "license")
        TakUrlProtocolImpl.takTlsSocketFactory = DefaultTakTlsSocketFactory(tak: tak)
        // Use this in case connections to the backend time out
        TakUrlProtocolImpl.allowSetConnectionCloseHeader = true
        // Configure Alamofire to use T.A.K
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = TimeInterval(TakUrlProtocolImpl.timeout / 1000)
        // Instructs iOS's stack to give preference to T.A.K for resolving HTTPS URLs
        configuration.protocolClasses?.insert(TakUrlProtocolImpl.self, at: 0)
        
        let delegate = SessionDelegate()
        let rootQueue = DispatchQueue(label: "org.alamofire.session.rootQueue")
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.underlyingQueue = rootQueue
        delegateQueue.name = "org.alamofire.session.sessionDelegateQueue"

        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

        super.init(session: session, delegate: delegate, rootQueue: rootQueue)
    }
}
```

As every request to the server is done through the library, the later has a `session: Session` attribute in `Connection` and `Service` constructors, with a default value of `AF`, corresponding to the default session for Alamofire. This way, one could set this parameter to `TakTlsSessionManager.sharedInstance` in the application and integrate Build38's secure channel requests. Every call to `AF.request(...)` is replaced by `TakTlsSessionManager.sharedInstance.request`, except for the `getEventsStreamed` method that might fail when using TAK SDK, as suggested in "Limitations when using Alamofire with T.A.K".

##### Secure Certificate Pinning

Following the documentation on "Pinning certificates", one should generate a certificate for each host we send an HTTP request to. For now, the use of wildcards in the name of the certificate such as `*.pryv.me` is not accepted. Consequently, the app user needs to add a host certificate for each service info and user: 

- one for the endpoint URL;
- one for the service info URL;
- one for the authentication URL (`authUrl` field from [auth request](https://api.pryv.com/reference/#auth-request));
- one for the polling URL (`poll` field from [auth request](https://api.pryv.com/reference/#auth-request)).

For each of these host, one needs to follow the guideline in "Pinning certificate" to generate the `.crt` certificate, encrypt it and add it to the XCode project. The app currently supports

- the endpoint for `testuser`: `testuser.pryv.me.crt`;
- the default `pryv.me` service info: `reg.pryv.me.crt`;
- the authentication: `sw.pryv.me.crt`;
- the polling: `access.pryv.me`.

As claims the documentation "Pinning certificates": 

> Make sure that the name of the certificate has the form **<host>.crt**. For instance, if you are connecting to https://httpbin.org/get you should name your certificate file “httpbin.org.crt”. It is very important that the file name is exactly as explained above. Otherwise, T.A.K Client will not be able to find the certificate at run time.

It is crucial for the correct behavior of the app to add a certificate for every different host we may query. Otherwise, TAK will ignore the request and we will receive no data, except for this error: 

```
2020-07-15 08:50:04.277177+0200 Pryv[2928:56161] Task <64CDDE0B-8279-41F7-BB2A-4D88BF08873E>.<1> finished with error [0] Error Domain=TAK.TakError Code=0 "(null)" UserInfo={_NSURLErrorRelatedURLSessionTaskErrorKey=(
  "LocalDataTask <64CDDE0B-8279-41F7-BB2A-4D88BF08873E>.<1>"
), _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <64CDDE0B-8279-41F7-BB2A-4D88BF08873E>.<1>}
```

Another solution could be to use [`open2.pryv.io`](https://open2.pryv.io/reg/service/info), which is DNS-less. Consequently, we just have to use the host `open2.pryv.io.crt` and the app would work.

#### Jailbreak detection

As suggested by the documentation, checking whether the device is jailbroken is very simple. One only needs to add a check `tak.isJailbroken()` at every app launch such that if the device is jailbroken, one does not let the user interact with the application. 

#### Signature generation

The signature is useful to verify the events retrieved from Pryv.io. In this case, a verified event is an event which was created in the iOS app, with a signature generated using `tak` object. This signature is generated as described in the documentation: 

```swift
let dataToBeSigned = event.data(using: String.Encoding.utf8)!
let signature = try tak.generateSignature(input: dataToBeSigned, signatureAlgorithm: .rsa2048)
```

and is added to the event parameters in the `client-data` with key `"tak-signature"`. If any retrieved event has a tak-signature corresponding to the signature of the event parameters, this event is displayed with a "verified" badge on the application. 