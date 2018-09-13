// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Copyright 2018-present, Pinterest, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
            .revision("e3c0dcb9dda0dc191034c061fdd4f0e4397ad527")),

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
