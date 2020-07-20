# Integration of BUILD38 into app-ios-swift-example

## Table of contents

[TOC]

## T.A.K Client SDK Integration

For the client DSK integration, I followed the steps listed in [TAK doc](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#xcode_integration2). 

Note that I did not include the two frameworks: TAK.framework nor TakTls.framework on GitHub. To import them, drap and drop the two folders `TAK-Client/iOS/Swift/libs/TAK.framework` and `TAK-Client/iOS/Swift/libs/TakTls.framework` in the `Project/Frameworks` folder in XCode project. Add them to the Project target and to the ProjectUITests target. Then, in `Project > General > Frameworks, Libraries, and Embedded Content`,  chose `embed & sign` for both of the frameworks. In `ProjectUITests > Build Phases > Link Binary with Libraries`, chose `Optional` status for both of the frameworks and do the same for `Project`. 

## T.A.K Client SDK Usage

### T.A.K. Initialization

Before using any feature provided by T.A.K., one needs to set up the SDK. 

In the `AppDelegate.swift` file, I added the code snippet given in the documentation for the initialization. I have tested it when launching the application and it works, i.e. the first time I opened the application, it successfully registered and the second time, it successfully checked the integrity, as expected. 

To use the TAK feature, the `tak` object needs to be passed to every view controller in the application from the `AppDelegate.swift`.

### Features used

According to the "Non-Functional features" part in the documentation, the idea is: 

> - Storing some necessary user credential (e.g. authentication token) in the [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).
> - Protecting some necessary app credential (e.g. API token) using the [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector).
> - Enabling client authentication in the backend and using the [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect to it.

Consequently, the following features will be used: 

[Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage) to store the user's authentication token and API endpoint.

[Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect when

- Requesting events;
- Creating events;
- Any other HTTP request in the application.

[File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector) is only used for encrypting the SSL certificates in secure channels. Otherwise, it is not used, as no huge storage (>1MB) is stored on the device, nor any asset. 

Jailbreak detection will be used in the T.A.K. initialization part, respectively to query the jailbreak status of the current device.

Signature Generation will be used to verify the events and streams created by a user via the iOS application. The events created in the application will be displayed with a "verified" tag.

The following features were not integrated in the app: 

- [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify) is not used as we already use jailbreak check in the application. 
- App re-packaging protection is not used as it is not yet available in iOS. 
- HealthCheck API would allow us to get visibility into the state of the T.A.K resources, services, and account. As it is not a DevOps application, we will not use it either. 

### Implementation of the features

#### Secure storage

The only object stored on the device is the API endpoint through the use of keychain. Now, instead of using iOS keychain, we can use Build38's secure storage to store the API endpoint and avoid the need for connection at every app launch. 

Therefore, there are two view controllers that require using secure storage: 

- `MainViewController`: as it is responsible for launching the authentication request and passing the result, i.e. the API endpoint, to the `ConnectionTabViewController`, it needs to store the API endpoint got from the connection in a secure storage and pass this storage to `ConnectionTabViewController`.
- `ConnectionTabViewController`: instead of getting the raw value of the API endpoint, it will get the storage that contains it. From this, it can create a connection bound to the stored API endpoint and pass this object to `ConnectionListTableViewController` and `ConnectionMapViewController`. As `ConnectionListTableViewController` and `ConnectionMapViewController` do not handle any API endpoint nor token directly, they do not need access to the storage. 

To securely implement writes and reads for the user's credentials, I followed the code snippets given in the [documentation](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).

#### Secure channel

To integrate secure channel, as `lib-swift` uses `Alamofire` for the HTTP requests, I could use the code snippet provided in the documentation section "Integration with Alamofire". However, this snippet uses an older version of Alamofire than `lib-swift`. Therefore, I had to modify it a bit to match the new classes in Alamofire (see `TakTlsSessionManager.swift`). 

As every request to the server is done through the library, I added a `session: Session` attribute to `Connection` and `Service` in [`lib-swift`](https://github.com/pryv/lib-swift/tree/build38-integrated), with a default value of `AF`, corresponding to the default session for Alamofire. This way, in the app, I could set this parameter to `TakTlsSessionManager.sharedInstance` in the application and integrate Build38's secure channel requests. Every call to `AF.request(...)` is replaced by `TakTlsSessionManager.sharedInstance.request`, except for the `getEventsStreamed` method that might fail when using TAK SDK, as suggested in "Limitations when using Alamofire with T.A.K".

##### Secure Certificate Pinning

Following the documentation on "Pinning certificates", we should generate a certificate for each host we send an HTTP request to. For now, the use of wildcards in the name of the certificate such as `*.pryv.me` is not accepted. Consequently, the app user needs to add a host certificate for each service info and user: 

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

As suggested by the documentation, checking whether the device is jailbroken is very simple. I only added a check `tak.isJailbroken()` at every app launch such that if the device is jailbroken, an alert appears and does not let the user interact with the application. 

#### Signature generation

// TODO