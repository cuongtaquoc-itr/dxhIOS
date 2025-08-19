#
# Be sure to run `pod lib lint dxhIOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'dxhIOS'
  s.version          = '0.1.0'
  s.summary          = 'DXH iOS SDK for device communication and ECG data streaming.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
DXH iOS SDK providing BLE/TCP communication, device control, and real-time ECG data parsing/streaming utilities for DXH devices.
                       DESC

  s.homepage         = 'https://github.com/cuongtaquoc-itr/dxhIOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cuongtaquoc@itrvn.com' => 'cuongtaquoc@itrvn.com' }
  s.source           = { :git => 'https://github.com/cuongtaquoc-itr/dxhIOS.git', :tag => s.version.to_s }
  s.swift_versions   = ['5.0']
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '14.0'

  s.source_files = 'dxhIOS/Classes/**/*'
  
  # s.resource_bundles = {
  #   'dxhIOS' => ['dxhIOS/Assets/*.png']
  # }

  s.public_header_files = 'dxhIOS/Classes/include/**/*.h'
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/dxhIOS/Classes/include',
    'OTHER_SWIFT_FLAGS' => '-suppress-warnings',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES'
  }
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'ReachabilitySwift', '~> 5.2.1'  # SPM product "Reachability"
  s.dependency 'CocoaAsyncSocket', '~> 7.6.4'
  s.dependency 'RxSwift', '~> 6.0'
  s.dependency 'CryptoSwift', '~> 1.8.2'
  # SwCrypt removed by replacing CRC32 with a local implementation
end
