// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_curl",
    platforms: [
        .iOS("12.2"),
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
            url: "https://github.com/ajinasokan/flutter_curl_binary/releases/download/0.9.1/Curl.ios.xcframework.zip",
            checksum: "a996b7be47a20c15abdc101f1ec58d360902b7f22d113e21c10424ebe00d8ac0"
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
