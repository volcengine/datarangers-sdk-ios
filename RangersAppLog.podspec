Pod::Spec.new do |s|
  s.name             = 'RangersAppLog'
  s.version          = '6.10.1'
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
    
    core.dependency 'RangersAppLog/VEInstall'
    core.source_files = [
      'BDAutoTracker/Classes/Core/**/**/*.{h,m,c}',
    ]
    core.public_header_files = 'BDAutoTracker/Classes/Core/Core/Header/*.h'
    core.exclude_files = [
      'BDAutoTracker/Classes/Core/Network/BDAutoTrackNetworkResponse.{h,m}',
    ]
    core.resource_bundles = {
      'RangersAppLog' => ['BDAutoTracker/Asserts/Core/*.js']
    }
  end
  
  s.subspec 'VEInstall' do |install|
    install.frameworks = ['Security', 'CoreTelephony', 'SystemConfiguration', 'CoreFoundation']
    install.library = 'z'
    install.source_files = [
      'BDAutoTracker/Classes/VEInstall/Core/**/*.{h,m,c}',
    ]
    install.public_header_files = [
      'BDAutoTracker/Classes/VEInstall/Core/Public/*.h'
    ]
  end
  
  s.subspec 'IDFA' do |idfa|
    idfa.frameworks = ['AdSupport', 'AppTrackingTransparency']
    idfa.source_files = [
      'BDAutoTracker/Classes/VEInstall/IDFA/**/*.{h,m,c}',
    ]
    idfa.public_header_files = [
      'BDAutoTracker/Classes/VEInstall/IDFA/**/*.h',
    ]
  end

  s.subspec 'Host' do |host|
    host.dependency 'RangersAppLog/Core'
    
    host.subspec 'CN' do |cn|
      cn.source_files = [
        'BDAutoTracker/Classes/Host/CN/**/*.{h,m}',
      ]
      cn.public_header_files = [
        'BDAutoTracker/Classes/Host/CN/*.h'
      ]
    end

    host.subspec 'SG' do |sg|
      sg.source_files = [
        'BDAutoTracker/Classes/Host/SG/**/*.{h,m}'
      ]
      sg.public_header_files = [
        'BDAutoTracker/Classes/Host/SG/*.h'
      ]
    end

    host.subspec 'VA' do |va|
      va.source_files = [
        'BDAutoTracker/Classes/Host/VA/**/*.{h,m}'
      ]
      va.public_header_files = [
        'BDAutoTracker/Classes/Host/VA/*.h'
      ]
    end
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
    # picker.resource_bundles = {
    #   'RangersAppLog' => ['BDAutoTracker/Assets/*.xcassets']
    # }
  end

  s.subspec 'DeviceOrientation' do |deviceOrientation|
    deviceOrientation.ios.deployment_target = '9.0'
    deviceOrientation.dependency 'RangersAppLog/Core'

    deviceOrientation.source_files = 'BDAutoTracker/Classes/DeviceOrientation/**/*.{h,m,c,mm}'
    deviceOrientation.public_header_files = 'BDAutoTracker/Classes/DeviceOrientation/**/*.h'
  end

  # C接口Bridge。在Unity Native Plugin等场景下使用。一般可以忽略。 
  s.subspec 'CBridge' do |c|
    c.dependency 'RangersAppLog/Core'
    c.source_files = 'BDAutoTracker/Classes/CBridge/*.{h,m}'
    c.public_header_files = 'BDAutoTracker/Classes/CBridge/*.h'
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
    h.dependency 'RangersAppLog/Picker'
    h.dependency 'OCMock','~> 3.8.1'
    h.dependency 'XcodeCoverage','>= 1.3.2'
    
    h.source_files = 'BDAutoTracker/Tests/**/*.{h,m}'
    h.resource_bundles = {
      'RangersAppLog-Tests' => ['BDAutoTracker/Tests/*.plist']
    }

  end

end
