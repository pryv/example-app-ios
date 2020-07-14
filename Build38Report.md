# Integration of BUILD38 into app-ios-swift-example

## T.A.K Client SDK Integration

For the client DSK integration, I followed the steps listed in [TAK doc](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#xcode_integration2). 

*As a note for the T.A.K. developpers, the "[Quick Start](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#quickstart-section)" link in the description is not working.* 

## T.A.K Client SDK Usage

### T.A.K. Initialization

Before using any feature provided by T.A.K., one needs to set up the SDK. 

// TODO !

### Features used

According to the "Non-Functional features" part in the documentation, the idea is: 

> - Storing some necessary user credential (e.g. authentication token) in the [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage).
> - Protecting some necessary app credential (e.g. API token) using the [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector).
> - Enabling client authentication in the backend and using the [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect to it.

Consequently, the following features will be used: 

1. [Secure Storage](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#secure-storage) to store 
   - The events created and retrieved by the user;
   - The user's authentication token and API endpoint.
2. [File Protector](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#protector) to protect
   - The API endpoint;
   - The application identifier.
3. [Secure Channel](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#tak_tls) to connect when
   - Requesting events;
   - Creating events;
   - Any other HTTP request in the application.

Jailbreak detection and HealthCheck API will be used in the T.A.K. initialization part, respectively to: 

- Query the jailbreak status of the current device;
- Get visibility into the state of the T.A.K resources, services, and account.

The [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify) feature will need to be implemented in the server to deal with any jailbroken device: 

> T.A.K will not, by default, react to rooted/jailbroken devices. Instead, it will forward this information to the T.A.K cloud during registration and validation operations, making this information available as well to the service provider through the [Fraud Management Interface](file:TAK-Client/docs/DeveloperDocumentation/TAK_Documentation.html#backend-verify). 

App re-packaging protection is not used as it is not yet available in iOS. 

### Implementation of the features

// TODO !

