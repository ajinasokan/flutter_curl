// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_curl",
    platforms: [
        .macOS("10.15"),
    ],
    products: [
        .library(name: "flutter-curl", targets: ["flutter_curl_objc", "flutter_curl_swift"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        // Pre-built curl binary downloaded from GitHub releases
        .binaryTarget(
            name: "Curl",
            url: "https://github.com/ajinasokan/flutter_curl_binary/releases/download/0.9.2/Curl.macos.xcframework.zip",
            checksum: "1fdc40be2aecf7a7599f59bec32205cc10709a7f3bf51a539c9cf795ecf6b2cf"
        ),
        // Objective-C target — registers the plugin and links curl
        .target(
            name: "flutter_curl_objc",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "flutter_curl_swift",
                "Curl",
            ],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("resolv"),
            ]
        ),
        // Swift target — handles method channel calls
        .target(
            name: "flutter_curl_swift",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
        ),
    ]
)
