# libcurl for Flutter [Alpha]

Flutter plugin to use [libcurl](https://curl.se/libcurl/) for HTTP calls in Flutter Android & iOS apps. HTTP stack built in to Dart as part of `dart:io` supports only HTTP 1.1. This plugin aims to bring upto date features in connectivity available in libcurl such as:

* HTTP2 with [Nghttp2](https://nghttp2.org)
* Automatic upgrade to HTTP2 from 1.1 with [ALPN](https://www.keycdn.com/support/alpn) TLS extension
* **Experimental** HTTP3 support with [quiche](https://github.com/cloudflare/quiche)
* Automatic upgrade to HTTP3 using [alt-svc](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc) header
* [Brotli](https://github.com/google/brotli) compression

## Getting started

Add to project using git source:

```yaml
dependencies:
  ...
  flutter_curl:
    git:
      url: https://github.com/ajinasokan/flutter_curl
```

Example usage:

```dart
import 'package:flutter_curl/flutter_curl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as paths;

// Initialize client
final altSvcPath = (await paths.getTemporaryDirectory()).path;
Client client = Client(
      altSvcCache: path.join(altSvcPath, "altsvc.txt"),
      verbose: true,
      interceptors: [
        // HTTPCaching(),
      ],
    );
await client.init();

// Send request
final res = await c.send(Request(
      method: "GET",
      url: "https://ajinasokan.com/",
      headers: {},
      body: [],
      verbose: true,
    ));

// Read response
print("Status: ${res.statusCode}");
print("HTTP: ${res.httpVersion}"); // 3 => H2, 30 => H3
res.headers.forEach((key, value) {
    print("$key: $value");
});
print(res.text());
```

## How it works

This plugin uses custom built libcurl libraries distributed via [releases](https://github.com/ajinasokan/flutter_curl/releases). If you would like to build these by yourself follow [instructions](https://github.com/curl/curl/blob/master/docs/HTTP3.md) in cURL project. The configuration used for above mentioned builds is:

* [BoringSSL+quiche](https://github.com/cloudflare/quiche) for SSL and HTTP3
* [Ngtcp2](https://github.com/ngtcp2/ngtcp2) for HTTP2
* [libbrotli](https://github.com/bagder/libbrotli)
* NDK min SDK: 21 (armv7a, arm64, x86_64), iOS min SDK: 8.0 (arm64, x86_64)
* Android binaries are packaged as **aar** and iOS binary as **framework**

This will be downloaded once the project builds for iOS or when pod install happens for iOS. In Android these binaries are dynamically linked and in iOS it is statically linked.

The cURL APIs are accessed directly in a different isolate in Flutter using the [dart:ffi](https://dart.dev/guides/libraries/c-interop) APIs(beta). Isolate is used to avoid unresponsiveness in the app as the cURL APIs are blocking.

## Reducing APK size

Flutter's `--target-platform` argument only removes its own native binaries for unspecified architectures. This is not adding `abiFilters` to the project gradle. So this doesn't remove the binaries for unspecified architectures from the plugins like flutter_curl. 

A workaround suggested in [flutter_vpn](https://pub.dev/packages/flutter_vpn) project is to add this logic to the project gradle config manually like below:

```groovy
android {
    ...
    buildTypes {
        ...
        release {
            ...
            ndk {
                if (!project.hasProperty('target-platform')) {
                    abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
                } else {
                    def platforms = project.property('target-platform').split(',')
                    def platformMap = [
                            'android-arm'  : 'armeabi-v7a',
                            'android-arm64': 'arm64-v8a',
                            'android-x86'  : 'x86',
                            'android-x64'  : 'x86_64',
                    ]
                    abiFilters = platforms.stream().map({ e ->
                        platformMap.containsKey(e) ? platformMap[e] : e
                    }).toArray()
                }
            }
    }
}
```
