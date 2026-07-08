#import <flutter_curl_objc/FlutterCurlPlugin.h>
@import flutter_curl_swift;

void curl_version();

@implementation FlutterCurlPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  curl_version();
  [SwiftFlutterCurlPlugin registerWithRegistrar:registrar];
}
@end
