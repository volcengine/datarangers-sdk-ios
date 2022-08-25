# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

source 'https://github.com/volcengine/volcengine-specs.git'
source 'https://cdn.cocoapods.org'

workspace 'BDAutoTracker'

target 'Example' do
  # Comment the next line if you don't want to use dynamic frameworks
  project 'Example/Example'
  use_frameworks!

  # Pods for Example
pod 'RangersAppLog', #'5.6.9-rc.10',
    :path => './',
    :subspecs => [
      'Host/SG',
      'Host/VA',
      'Host/CN',
      'Core',
      'Log',
      'Picker',
      'UITracker',
      'CBridge',
      'DeviceOrientation',
      'Exposure',
      'VEInstall',
      'IDFA'
    ],
    :testspecs => [
      'Tests',
    ],
    :inhibit_warnings => false

  target 'ExampleTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'ExampleUITests' do
    # Pods for testing
  end

end
