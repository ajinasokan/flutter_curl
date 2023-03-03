#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_curl.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_curl'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
  s.vendored_frameworks = 'Curl.xcframework'

  s.prepare_command = <<-CMD
    if [ ! -d "Curl.xcframework" ]; then  
      url=https://github.com/ajinasokan/flutter_curl_binary/releases/download/0.3.0%2B3/Curl.xcframework.zip
      file=Curl.xcframework.zip  
      wget -O $file $url 2>/dev/null || curl -Lo $file $url
      unzip Curl.xcframework.zip
      rm -f Curl.xcframework.zip
    fi
  CMD

  s.xcconfig = {
       'OTHER_LDFLAGS' => '-lz'
  }
end
