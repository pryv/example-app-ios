# Integration of BUILD38 into app-ios-swift-example

## Table of contents

[TOC]

## T.A.K Client SDK Integration

For the client DSK integration, I followed the steps listed in [TAK doc](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#xcode_integration2). 

Note that I did not include the two frameworks: TAK.framework nor TakTls.framework on GitHub. To import them, drap and drop the two folders `TAK-Client/iOS/Swift/libs/TAK.framework` and `TAK-Client/iOS/Swift/libs/TakTls.framework` in the `Project/Frameworks` folder in XCode project. Add them to the Project target and to the ProjectUITests target. Then, in `Project > General > Frameworks, Libraries, and Embedded Content`,  chose `embed & sign` for both of the frameworks and in `ProjectUITests > Build Phases > Link Binary with Libraries`, chose `Optional` status for both of the frameworks. 

*As a note for T.A.K. developpers, the "[Quick Start](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#quickstart-section)" link in the description is not working.* 

## T.A.K Client SDK Usage

### T.A.K. Initialization

Before using any feature provided by T.A.K., one needs to set up the SDK. 

In the `AppDelegate.swift` file, I added the code snippet given in the documentation for the initialization. I have tested it when launching the application and it works, i.e. the first time I opened the application, it successfully registered and the second time, it successfully checked the integrity, as expected. 

To use the TAK feature, the `tak` object needs to be passed to every view controller in the application from the `AppDelegate.swift`.

#### Remarks

Some points which require attention for the app-ios-swift-example (notified by a `// TODO` in the code): 

- Upon registration or re-registration, 

> It is recommended (but not required) to send the T.A.K ID to your server's backend and bind it to the current user. It will allow you to use the verification interface of the T.A.K cloud.

- As the app will continuously send and receive data from the server, the tak cannot be `released`.

Some points which require attention in the code snippet for the T.A.P. SDK:

- The constant `isRegistered` is an optionnal, which cannot be used directly in an `if` clause. 
- The constants `tak`, `registrationResponse` and `checkIntegrityResponse` are created with a `try` clause, which is not within a `do {} catch {}` clause.
- The documentation concerning the `register` function suggests to provide `NULL` for the `userHash` parameter, but `NULL` does not exist in Swift.

### Features used

According to the "Non-Functional features" part in the documentation, the idea is: 

> - Storing some necessary user credential (e.g. authentication token) in the [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).
> - Protecting some necessary app credential (e.g. API token) using the [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector).
> - Enabling client authentication in the backend and using the [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect to it.

Consequently, the following features will be used: 

1. [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage) to store the user's authentication token and API endpoint.
2. [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect when
   - Requesting events;
   - Creating events;
   - Any other HTTP request in the application.

Jailbreak detection will be used in the T.A.K. initialization part, respectively to query the jailbreak status of the current device.

Signature Generation could be a nice feature to add, especially for the connection requests. This will need support from the server.

The [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify) feature will also need to be implemented in the server to deal with any jailbroken device: 

> T.A.K will not, by default, react to rooted/jailbroken devices. Instead, it will forward this information to the T.A.K cloud during registration and validation operations, making this information available as well to the service provider through the [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify). 

The following features were not integrated in the app: 

- App re-packaging protection is not used as it is not yet available in iOS. 
- [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector) is not used either as no huge storage (>1MB) is stored on the device, nor any asset. 
- HealthCheck API would allow us to get visibility into the state of the T.A.K resources, services, and account. As we do not yet support TAK in the server, I would suggest to keep this part for later. 

### Implementation of the features

#### Secure storage

The only object stored on the device is the API endpoint through the use of keychain. Now, instead of using iOS keychain, we can use Build38's secure storage to store the API endpoint and avoid the need for connection at every app launch. 

Therefore, there are two view controllers that require using secure storage: 

- `MainViewController`: as it is responsible for launching the authentication request and passing the result, i.e. the API endpoint, to the `ConnectionTabViewController`, it needs to store the API endpoint got from the connection in a secure storage and pass this storage to `ConnectionTabViewController`.
- `ConnectionTabViewController`: instead of getting the raw value of the API endpoint, it will get the storage that contains it. From this, it can create a connection bound to the stored API endpoint and pass this object to `ConnectionListTableViewController` and `ConnectionMapViewController`. As `ConnectionListTableViewController` and `ConnectionMapViewController` do not handle any API endpoint nor token directly, they do not need access to the storage. 

To securely implement writes and reads for the user's credentials, I followed the code snippets given in the [documentation](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).

#### Secure channel

To integrate secure channel, 

- I generated the encrypted `*.pryv.me` certificate, as suggested in the documentation, and added it to the application files. 
  
  - Note that, in order to authenticate the connecting clients, the server will need to configure Build38’s trust chain (request it on the [Service Desk](https://build38service.atlassian.net/servicedesk/customer/portal/)) in the reverse proxy (such as Apache or Nginx). 
  
- As `lib-swift` uses `Alamofire` for the HTTP requests, I could use the code snippet provided in the documentation section "Integration with Alamofire". However, this snippet uses an older version of Alamofire than `lib-swift`. Therefore, I had to modify it a bit to match the new classes in Alamofire (see `TakTlsSessionManager.swift`). As every request to the server is done through the library, I chose to make a new branch, called `build38-integrated` in [`lib-swift`](https://github.com/pryv/lib-swift/tree/build38-integrated) to integrate `TakTlsSessionManager.swift` requests in the library. Every call to `AF.request(...)` was replaced by `TakTlsSessionManager.sharedInstance.request`, except for the `getEventsStreamed` method that might fail when using TAK SDK, as suggested in "Limitations when using Alamofire with T.A.K".

    

  The app will install the pod from this branch, whereas a user that does not have a TAK license could still use the `master` version. *Note that to be able to build the application, the user will need to add his own license and frameworks to the Pod/PryvSwiftKit project.*

*!!! Note: this part does not work yet !!! See "Encountered problems" for more details*

##### Encountered problems

When running the application, I cannot create nor see the events, except for the `getEventsStreamed` method that uses `AF.request` instead of `TakTlsSessionManager.sharedInstance.request`. These are the logs I get: 

```
Success: T.A.K check integrity was successful
T.A.K library has been already initialized, it is recommended to destroy TAK object after use of it has been finished
2020-07-15 08:50:04.277177+0200 Pryv[2928:56161] Task <64CDDE0B-8279-41F7-BB2A-4D88BF08873E>.<1> finished with error [0] Error Domain=TAK.TakError Code=0 "(null)" UserInfo={_NSURLErrorRelatedURLSessionTaskErrorKey=(
  "LocalDataTask <64CDDE0B-8279-41F7-BB2A-4D88BF08873E>.<1>"
), _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <64CDDE0B-8279-41F7-BB2A-4D88BF08873E>.<1>}
```

Even when using a single TAK object, as suggested on line 2, the problem persists. I think that this may be a problem of certificate. Indeed, the documentation "Pinning certificates" claims: 

> Make sure that the name of the certificate has the form **<host>.crt**. For instance, if you are connecting to https://httpbin.org/get you should name your certificate file “httpbin.org.crt”. It is very important that the file name is exactly as explained above. Otherwise, T.A.K Client will not be able to find the certificate at run time.

The certificate I created has the name "*.pryv.me.crt". As every query has a different path and may have a different domain, even different from `pryv.me`, this may be a problem in the application that trigger the error above.

#### Jailbreak detection

As suggested by the documentation, checking whether the device is jailbroken is very simple. I only added a check `tak.isJailbroken()` at every app launch such that if the device is jailbroken, an alert appears and does not let the user interact with the application. 

*As a note for T.A.K. developpers, it seems that the code snippet are not correctly sorted for C, Kotlin and Swift.* 