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
        .package(url: "https://github.com/yonaskolb/XcodeGen.git",
            .revision("2ebfc9a9dc23ce029b81da8408d8991a9fc77a58")),

        // Changes reside in the xchammer branch
        .package(url: "https://github.com/pinterest/Tulsi.git",
            .revision("6ebee5d7d8b98b834515012f01c455fb54c2e78a")),

        // Note: XcodeGen now transitively depends on this one, so the versions
        // must match!
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from:
            "2.1.0"),

        .package(url: "https://github.com/Carthage/Commandant.git", from:
            "0.12.0"),
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
