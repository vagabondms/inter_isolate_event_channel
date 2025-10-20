#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint inter_isolate_event_channel.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'inter_isolate_event_channel'
  s.version          = '1.0.2'
  s.summary          = 'Flutter plugin for broadcasting events across multiple isolates/engines.'
  s.description      = <<-DESC
Flutter plugin for broadcasting events across multiple isolates/engines via native platform channels.
                       DESC
  s.homepage         = 'https://github.com/minseok-joel/inter_isolate_event_channel'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Minseok Joel' => 'noreply@github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'inter_isolate_event_channel_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
