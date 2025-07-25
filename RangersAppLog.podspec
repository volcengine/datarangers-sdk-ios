Pod::Spec.new do |s|
  s.name             = 'RangersAppLog'
  s.version          = '6.17.4'
  s.summary          = '火山引擎数据采集SDK'
  s.description      = '火山引擎数据采集SDK'
  s.homepage         = 'https://github.com/bytedance/RangersAppLog'
  s.author           = { 'zhangtianfu' => 'zhangtianfu@bytedance.com' }
  s.source           = { :git => 'https://github.com/volcengine/datarangers-sdk-ios.git', :tag => "v#{s.version.to_s}"}
  s.ios.deployment_target = '9.0'
  s.default_subspecs = 'Host', 'Core', 'Log'
  s.requires_arc = true
  s.static_framework = true
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'BITCODE_GENERATION_MODE' => 'bitcode',
  }
  s.subspec 'Core' do |core|
    core.frameworks =  'CoreGraphics','Foundation','Security','CoreTelephony','CoreFoundation','SystemConfiguration','WebKit'
    core.ios.frameworks = 'UIKit'
    core.osx.frameworks = 'AppKit'
    core.library = 'z','sqlite3'

    core.source_files = [
      'BDAutoTracker/Classes/Core/**/**/*.{h,m,c}',
    ]
    core.public_header_files = 'BDAutoTracker/Classes/Core/Core/Header/*.h'
    core.exclude_files = [
      'BDAutoTracker/Classes/Core/Network/BDAutoTrackNetworkResponse.{h,m}',
    ]
    core.resource_bundles = {
      'RangersAppLog' => ['BDAutoTracker/Asserts/Core/*.txt']
    }
  end
  
  s.subspec 'Log' do |tracker|
    tracker.dependency 'RangersAppLog/Core'

    tracker.source_files = 'BDAutoTracker/Classes/Log/**/*.{h,m,c,mm}'
    tracker.private_header_files = 'BDAutoTracker/Classes/Log/**/*.h'
  end
  
  s.subspec 'UITracker' do |tracker|
    tracker.ios.deployment_target = '9.0'
    tracker.frameworks = 'WebKit'
    tracker.dependency 'RangersAppLog/Core'

    tracker.source_files = 'BDAutoTracker/Classes/UITracker/**/*.{h,m,c,mm}'
    tracker.public_header_files = 'BDAutoTracker/Classes/UITracker/Header/*.h'
  end

   s.subspec 'Picker' do |picker|
    picker.ios.deployment_target = '9.0'
    picker.frameworks = 'CoreText'
    picker.dependency 'RangersAppLog/UITracker'
    picker.dependency 'RangersAppLog/Log'

    picker.source_files = 'BDAutoTracker/Classes/Picker/**/*.{h,m,c,mm}'
    picker.public_header_files = 'BDAutoTracker/Classes/Picker/Header/*.h'
  end

  s.subspec 'DeviceOrientation' do |deviceOrientation|
    deviceOrientation.ios.deployment_target = '9.0'
    deviceOrientation.dependency 'RangersAppLog/Core'

    deviceOrientation.source_files = 'BDAutoTracker/Classes/DeviceOrientation/**/*.{h,m,c,mm}'
    deviceOrientation.public_header_files = 'BDAutoTracker/Classes/DeviceOrientation/**/*.h'
  end
  
  s.subspec 'Exposure' do |exp|
    exp.ios.deployment_target = '9.0'
    exp.source_files = [
      'BDAutoTracker/Classes/Exposure/Sources/*.{h,m}'
    ]
    exp.public_header_files = [
      'BDAutoTracker/Classes/Exposure/Sources/BDAutoTrackExposure.h',
    ]
    exp.dependency 'RangersAppLog/Core'
    exp.dependency 'RangersAppLog/UITracker'
  end
  
  s.test_spec 'Tests' do |h|
    h.requires_app_host = false
    h.dependency 'XcodeCoverage','>= 1.3.2'
    
    h.source_files = 'BDAutoTracker/Tests/**/*.{h,m}'
    h.resource_bundles = {
      'RangersAppLog-Tests' => ['BDAutoTracker/Tests/*.plist']
    }

  end

end
