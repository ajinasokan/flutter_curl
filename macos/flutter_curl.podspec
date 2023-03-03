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
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.vendored_frameworks = 'Curl.framework'

  s.prepare_command = <<-CMD
    if [ ! -d "Curl.framework" ]; then  
      url=https://github.com/ajinasokan/flutter_curl_binary/releases/download/0.3.0%2B3/Curl.framework.zip
      file=Curl.framework.zip  
      wget -O $file $url 2>/dev/null || curl -Lo $file $url
      unzip Curl.framework.zip
      rm -f Curl.framework.zip
    fi
  CMD

  s.xcconfig = {
       'OTHER_LDFLAGS' => '-lz -lresolv'
  }
end
