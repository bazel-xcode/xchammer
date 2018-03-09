// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCHammer",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
          name: "XCHammer",
          targets: ["XCHammer"]),
    ],
    dependencies: [
        // xchammer branches
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", .revision("e1b9bc29f7c4538757fc9481d73948b1ccd76ad6")),
        .package(url: "https://github.com/pinterest/Tulsi.git",
            .revision("499fe40f63580d5bbd4a133241ee3083a169c00f")),
        // other deps
        .package(url: "https://github.com/jpsim/Yams.git", from: "0.3.6"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.12.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "XCHammer",
            dependencies: [
              "XcodeGenKit",
              "ProjectSpec",
              "TulsiGenerator",
              "Commandant",
              "ShellOut"
         ])
    ],
    swiftLanguageVersions: [3]
)
