# 0.9.3

* Updated Curl binary
* Updated CA certificate bundle. Drops emSign ECC Root CA - G3, emSign Root
  CA - C1 and emSign ECC Root CA - C3

# 0.9.2

* Android fetches the Curl binary through Gradle
* In verbose mode the curl version goes to the request log stream

# 0.9.1

* Fixed crash in iOS and macOS release builds. Curl now ships as a dynamic
  framework, so all of its symbols stay in the app's export table
* Minimum iOS version is now 12.2, to match the Curl framework

# 0.9.0

* Swift Package Manager (SPM) support
* Updated Curl binary

# 0.8.0

* Updated Curl binary

# 0.7.0

* New Android Curl binary with 16K Page Size support

# 0.6.0

* Removed deprected registerWith handler
* Exposed libcurl error codes as `Response.errorCode` for debugging

# 0.5.1

* Bundling CA certificates and is used by default
* Fixed HTTP3 TLS issue in iOS
* Certificate pinning

# 0.5.0

* Upgraded all binary dependencies

# 0.3.0

* Flutter 3.10 migration

# 0.2.0

* Upgraded `ffi` dependency
* Patch to support new FFI semantics for structs
* Library now requires Dart >= 2.17.0

## 0.1.1

* Fixes direct local .aar file dependencies issue with new Gradle

## 0.1.0

* Null safety migration

## 0.0.1

* Initial release
