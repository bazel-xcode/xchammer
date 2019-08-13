// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCConfigDumper",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "XCConfigDumperCore",
            targets: ["XCConfigDumperCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "XCConfigDumperCore",
            dependencies: []
        ),
        .target(
            name: "xcconfigdumper",
            dependencies: ["XCConfigDumperCore", "SPMUtility", "SwiftShell"]
        ),
        .testTarget(
            name: "XCConfigDumperTests",
            dependencies: ["XCConfigDumperCore"]
        ),
    ]
)
