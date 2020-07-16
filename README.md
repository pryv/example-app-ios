# Pryv iOS example app

Minimalistic app to discover Pryv [`lib-swift`](https://github.com/pryv/lib-swift) and [`ios-healthkit-bridge`](https://github.com/pryv/ios-healthkit-bridge) usage

You will get:

* **MainViewController** a simple view to sign in using a customizable service info  
* **AuthViewController** a web view to sign in and give permissions to the app from a Pryv account
* **ConnectionListTableViewController** a table view to show the last 20 events and to create new ones for a single connection
* **ConnectionMapViewController** a map view to show the position events for a single connection

If authorized, the application will get the updates from HealthKit for date of birth, wheelchair use, body mass, height, body mass index and active energy burned. These updates will trigger the creation of a new event in Pryv.io backend with the content of the sample received from HealthKit.

The application will also create a HealthKit sample for body mass upon the creation of a simple event with stream id `bodyMass` in the application.

## Install

* install cocoa pods [cocoapods.org](https://cocoapods.org)
From `Project` folder
* run `pod install`
* if needed run `pod update`
* open Example.xcworkspace (not Example.xcodeproj)

## Screenshots

<figure>
  <figcaption>MainViewController: </figcaption>
  <img src="https://github.com/pryv/app-swift-example/blob/master/Screenshots/MainViewController.png" title="MainViewController" height="700">
</figure>


<figure>
  <figcaption>AuthViewController: </figcaption>
  <img src="https://github.com/pryv/app-swift-example/blob/master/Screenshots/AuthViewController.png" title="MainViewController" height="700">
</figure>


<figure>
  <figcaption>ConnectionListTableViewController: </figcaption>
  <img src="https://github.com/pryv/app-swift-example/blob/master/Screenshots/ConnectionListTableViewController.png" title="MainViewController" height="700">
</figure>


<figure>
  <figcaption>ConnectionMapViewController: </figcaption>
  <img src="https://github.com/pryv/app-swift-example/blob/master/Screenshots/ConnectionMapViewController.png" title="ConnectionMapViewController" height="700">
</figure>

## Support and warranty

Pryv provides this software for educational and demonstration purposes with no support or warranty.

## License

Revised BSD license
