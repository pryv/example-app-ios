# Integration of BUILD38 into app-ios-swift-example

## Table of contents

[TOC]

## T.A.K Client SDK Integration

For the client DSK integration, I followed the steps listed in [TAK doc](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#xcode_integration2). 

*As a note for the T.A.K. developpers, the "[Quick Start](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#quickstart-section)" link in the description is not working.* 

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

Jailbreak detection and HealthCheck API will be used in the T.A.K. initialization part, respectively to: 

- Query the jailbreak status of the current device;
- Get visibility into the state of the T.A.K resources, services, and account.

Signature Generation could be a nice feature to add, especially for the connection requests. This will need support from the server.

The [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify) feature will also need to be implemented in the server to deal with any jailbroken device: 

> T.A.K will not, by default, react to rooted/jailbroken devices. Instead, it will forward this information to the T.A.K cloud during registration and validation operations, making this information available as well to the service provider through the [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify). 

App re-packaging protection is not used as it is not yet available in iOS. [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector) is not used either as no huge storage (>1MB) is stored on the device, nor any asset.

### Implementation of the features

#### Secure storage

There are three view controllers that require using secure storage, as they interact with the API endpoint and its token: 

- `MainViewController`: as it is responsible for launching the authentication request and passing the result to the `ConnectionTabViewController`, it needs to store the API endpoint got from the connection in a secure storage and pass this storage to `ConnectionTabViewController`.
- `ConnectionTabViewController`: instead of getting the raw value of the API endpoint, it will get the storage that contains it. It is the one responsible for passing the objects to `ConnectionListTableViewController` and `ConnectionMapViewController`. As `ConnectionTabViewController` and `ConnectionMapViewController` do not handle any API endpoint nor token directly, `ConnectionTabViewController` simply passes this storage to `ConnectionListTableViewController`. 
- `ConnectionListTableViewController`: it deals directly with API endpoint, from which is extracts the token. The token is used to create socket.io URL. Consequently, it needs to use the secure storage to retrieve the API endpoint and to store the URL.

To implement securely write and read the user's credentials, I followed the code snippets given in the [documentation](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).

#### Secure channel

To integrate secure channel, 

- I generated the encrypted `*.pryv.me` certificate, as suggested in the documentation, and added it to the application files. 
  - Note that, in order to authenticate the connecting clients, the server will need to configure Build38’s trust chain (request it on the [Service Desk](https://build38service.atlassian.net/servicedesk/customer/portal/)) in the reverse proxy (such as Apache or Nginx). 
- As `lib-swift` is using `Alamofire` for the HTTP requests, we could use the code snippet provided in the documentation section "Integration with Alamofire". As this snippet does not use the same version of Alamofire as we do in `lib-swift`, I had to downgrade the version of Alamofire in the library. Moreover, to keep the library external from Build38's SDK, I only changed the requests within the library in the `Pods/` files of the application.
