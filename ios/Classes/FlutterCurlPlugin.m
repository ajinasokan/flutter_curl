#import "FlutterCurlPlugin.h"
#if __has_include(<flutter_curl/flutter_curl-Swift.h>)
#import <flutter_curl/flutter_curl-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_curl-Swift.h"
#endif

void curl_version();

@implementation FlutterCurlPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  curl_version();
  [SwiftFlutterCurlPlugin registerWithRegistrar:registrar];
}
@end
