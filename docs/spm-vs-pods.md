# Shipping a prebuilt static libcurl: CocoaPods vs Swift Package Manager

Context: `flutter_curl` is an FFI plugin. On iOS/macOS the Dart side uses
`DynamicLibrary.process()`, so curl must be statically linked into the app
(the `curl_version()` call in the ObjC target exists only to force the linker
to keep the symbols). The prebuilt binary is a static `ar` archive.

## The binary

- `flutter_curl_binary` produces a fat static archive (`nghttp2`, `quiche`,
  `brotli`, `c-ares`, `curl` combined via `libtool -static`).
- It was packaged as `Curl.framework/Curl` — a bare `.framework` dir containing
  only the static archive (no `Info.plist`, `Headers/`, or `Modules/`).

## Why it worked under CocoaPods

- Consumed via `s.vendored_frameworks = 'Curl.framework'` (macOS) /
  `'Curl.xcframework'` (iOS).
- CocoaPods links it with `-framework Curl` and, because the Mach-O is a
  static archive, does not add it to the "Embed Frameworks" phase.
- Nothing is copied into the app bundle → the framework never has to be a valid
  bundle → a missing `Info.plist` is harmless.

## Why it fails under Swift Package Manager

- Consumed via a `.binaryTarget` → xcframework.
- SPM/Xcode decides embed-vs-link from the xcframework's `LibraryPath` type,
  not from the Mach-O:
  - `LibraryPath = Curl.framework` → treated as a framework product → always
    embedded/codesigned into `App.app/Contents/Frameworks/`.
- The embed step requires a valid bundle, so the bare framework fails:
  - no `Info.plist` → `Curl.framework did not contain an Info.plist`
  - with a flat `Info.plist` → `expected Versions/Current/Resources/Info.plist`
    (macOS wants a full *versioned* framework bundle)
- Not an SPM limitation — SPM fully supports prebuilt static libs. It just
  requires the idiomatic packaging instead of the CocoaPods "static archive
  disguised as a framework" trick.

## The fix: ship a static-*library* xcframework

- `LibraryPath = libCurl.a` (a static library) → Xcode links, never embeds.
  No `Info.plist`/bundle ceremony, symbols end up in the app binary and export
  correctly for FFI (`DynamicLibrary.process()`).
- Produce it with:
  ```
  xcodebuild -create-xcframework -library libCurl.a -output Curl.xcframework
  # iOS (device + simulator slices):
  xcodebuild -create-xcframework \
    -library Curl_arm64_iphone.a \
    -library Curl_iphonesimulator.a \
    -output Curl.xcframework
  ```
- Reference a plain zipped xcframework directly — no `.artifactbundle` wrapper:
  ```swift
  .binaryTarget(
      name: "Curl",
      url: ".../<tag>/Curl-macos.xcframework.zip",
      checksum: "<swift package compute-checksum Curl.xcframework.zip>"
  )
  ```

## Unrelated Swift/ObjC wiring notes (mixed-language SPM plugin)

- Swift class + registration must be `@objc` (`@objc public class …`,
  `@objc public static func register(with:)`), or SPM emits no `-Swift.h`.
- Import the Swift target from ObjC as a Clang module (`@import flutter_curl_swift;`)
  rather than `#import <flutter_curl_swift/flutter_curl_swift-Swift.h>`; SPM
  exposes it via a generated module map.
