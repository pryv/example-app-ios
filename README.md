# Pryv iOS example app
![Pryv iOS Swift app example](https://github.com/pryv/app-ios-swift-example/workflows/Pryv%20iOS%20Swift%20app%20example/badge.svg)

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

## Install

* install cocoa pods [cocoapods.org](https://cocoapods.org)
From `Project` folder
* run `pod install`
* if needed run `pod update`
* open Example.xcworkspace (not Example.xcodeproj)


## Support and warranty

Pryv provides this software for educational and demonstration purposes with no support or warranty.

## License

Revised BSD license
