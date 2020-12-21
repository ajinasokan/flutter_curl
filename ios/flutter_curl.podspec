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
  s.vendored_frameworks = 'Curl.framework'

  s.prepare_command = <<-CMD
    if [ ! -d "Curl.framework" ]; then  
      url=http://localhost:8000/Curl.framework.zip
      file=Curl.framework.zip  
      wget -O $file $url 2>/dev/null || curl -o $file $url
      unzip Curl.framework.zip
      rm -f Curl.framework.zip
    fi
  CMD

  s.xcconfig = {
       'OTHER_LDFLAGS' => '-lz'
  }
end
