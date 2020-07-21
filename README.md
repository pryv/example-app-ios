# Pryv iOS example app

Minimalistic app to discover Pryv [`lib-swift`](https://github.com/pryv/lib-swift) and [`bridge-ios-healthkit`](https://github.com/pryv/bridge-ios-healthkit) usage

You will get:

* **MainViewController** a simple view to sign in using a customizable service info  
* **AuthViewController** a web view to sign in and give permissions to the app from a Pryv account
* **ConnectionListTableViewController** a table view to show the last 20 events and to create new ones for a single connection
* **ConnectionMapViewController** a map view to show the position events for a single connection

If authorized, the application will get the updates from HealthKit for date of birth, wheelchair use, body mass, height, body mass index, active energy burned and workout. These updates will trigger the creation of a new event in Pryv.io backend with the content of the sample received from HealthKit.

The application will also create a HealthKit sample for body mass upon the creation of a simple event with stream id `bodyMass` in the application.

These app views correspond to each of the view controllers described above: MainViewController, AuthViewController, ConnectionListTableViewController and ConnectionMapViewController respectively.

| Service info                                                 | Authentication and authorization                             | Connection list                                              | Connection map                                               |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| <img src="Screenshots/MainViewController.png" title="MainViewController" style="zoom:33%;"> | <img src="Screenshots/AuthViewController.png" style="zoom:33%;" /> | <img src="Screenshots/ConnectionListTableViewController.png" style="zoom:33%;" /> | <img src="Screenshots/ConnectionMapViewController.png" style="zoom:33%;" /> |

The app integrates the [Build38 T.A.K (Trusted Application Kit)](https://build38.com/solution/) solution to protect against the most common security threats. For more information about the features used, see the [integration report](https://github.com/pryv/app-ios-swift-example/blob/build38-integration/Build38Report.md). 

## Install

* install cocoa pods [cocoapods.org](https://cocoapods.org)
From `Project` folder
* run `pod install`
* if needed run `pod update`
* open Example.xcworkspace (not Example.xcodeproj)
* add your Build38 T.A.K. license and frameworks:
  *  in XCode, `file > Add files to Example ...`, select your tak license and add it to the Example and the ExampleUITests targets
  *  drag and drop the two folders `TAK-Client/iOS/Swift/libs/TAK.framework` and `TAK-Client/iOS/Swift/libs/TakTls.framework` in the `Example/Frameworks` folder in XCode project
  * add the frameworks to the Example and the ExampleUITests targets
  * in `Example > General > Frameworks, Libraries, and Embedded Content`,  chose `embed & sign` for both of the frameworks
  * in `Example > Build Phases > Link Binary with Libraries`, chose `Optional` status for both of the frameworks
  * in `ExampleUITests > Build Phases > Link Binary with Libraries`, chose `Optional` status for both of the frameworks

Note that for every HTTP request, one needs to add the host SSL certificate; wildcards are not yet supported. Follow the procedure to generate the certificate `.crt` file and its encrypted `.tak` version, as described in the T.A.K. documentation and add the `.tak` encrypted certificate to the Example and ExampleUITest target. 


## Support and warranty

Pryv provides this software for educational and demonstration purposes with no support or warranty.

## License

Revised BSD license
