source 'https://github.com/pryv/lib-swift.git'
source 'https://github.com/pryv/bridge-ios-healthkit.git'
source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

project 'Example.xcodeproj'
target 'Example' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Example
  pod 'PryvSwiftKit', :git => 'https://github.com/pryv/lib-swift.git', :branch => 'master'
  pod 'HealthKitBridge', :git => 'https://github.com/pryv/bridge-ios-healthkit', :branch => 'master'
  pod 'RLBAlertsPickers', '~> 1.1.1'

  target 'ExampleUITests' do
    # Pods for testing
  end

end
