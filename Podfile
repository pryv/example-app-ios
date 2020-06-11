source 'https://github.com/alemannosara/PryvApiSwiftKitSpecs.git'
source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'PryvApiSwiftKitExample' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for PryvApiSwiftKitExample
  pod 'Mocker'
  pod 'PryvApiSwiftKit', :git => 'https://github.com/pryv/lib-swift.git', :branch => 'connection-object'
  pod 'SwiftKeychainWrapper'
  pod 'FileBrowser', '~> 1.0'

  target 'PryvApiSwiftKitExampleTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'PryvApiSwiftKitExampleUITests' do
    # Pods for testing
  end

end
