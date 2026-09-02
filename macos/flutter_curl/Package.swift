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
            url: "https://github.com/ajinasokan/flutter_curl_binary/releases/download/0.9.1/Curl.macos.xcframework.zip",
            checksum: "5b04d539b2c41c628659b62938775861a06cf7e0b6f215831f4cfc0e6d3c5157"
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
