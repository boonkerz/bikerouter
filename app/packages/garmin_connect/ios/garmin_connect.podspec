Pod::Spec.new do |s|
  s.name             = 'garmin_connect'
  s.version          = '0.1.0'
  s.summary          = 'Wegwiesel local plugin around Garmin Connect IQ Mobile SDK.'
  s.description      = 'Sends share-code messages from the iPhone app to a paired Edge running Wegwiesel Sync.'
  s.homepage         = 'https://wegwiesel.app'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Thomas Peterson' => 'info@thomas-peterson.de' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.vendored_frameworks = 'Frameworks/ConnectIQ.xcframework'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end
