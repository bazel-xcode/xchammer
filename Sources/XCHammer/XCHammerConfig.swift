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

import Foundation

struct XCHammerTargetConfig: Codable {
    /// Command line arguments for each target
    let commandLineArguments: [String]?
    
    /// Environment Variables for each target
    let environmentVariables: [String: String]?

    /// Bazel Target options

    /// Build options passed to the Bazel invocation
    let buildBazelOptions: String?

    /// Startup options passed to the Bazel build invocation
    let buildBazelStartupOptions: String?

    /// Template for the `Bazel build` runscript relative to the
    /// workspace root.
    /// Variables:
    /// __BAZEL_COMMAND__
    /// This is the actual build invocation.
    /// 
    /// i.e.
    /// # MyTemplate.sh.tpl
    /// # Some scripting things..
    /// __BAZEL_COMMAND__
    let buildBazelTemplate: String?
}

struct XCHammerProjectConfig: Codable {
    /// Paths for included source files and directories.
    /// These paths are relative to the workspace root.
    /// Recursive Directory: Path/**
    /// Entire Directory: Path/
    /// File or Directory: Path/ToFileOrDir
    ///
    /// Generally, include all paths where sources are contained.
    ///
    /// Granularity is useful to decompose projects into a xcworkspace
    /// @note: if a given target's BUILD file is not included, it will not be
    /// included. This is useful for creating Xcode projects containing
    /// specific targets.
    ///
    /// @note XCHammer targets are configured to build and link dependencies
    /// across a given workspace.
    let paths: [String]?

    /// Bazel Project Options

    /// Provide Bazel options for a given platform:
    /// i.e.
    /// ios_x86_64
    /// If no options are provided, then defaults are applied.
    /// @see BazelBuildSettings
    /// Interesting platforms include
    /// macos_x86_64
    /// ios_x86_64, ios_i386, ios_arm64, ios_armv7
    /// watchos_i386, watchos_armv7k, tvos_x86_64
    /// @note: this is written into a python program which is later
    /// serialized. Spaces and escapes matter.
    let buildBazelPlatformOptions: [String: [String]]?

    /// Enable generation of transitive Xcode targets.
    /// Defaults to `true`
    /// @note this is _generally_ required for Xcode projects to build with
    /// Xcode.
    /// For Non Xcode enabled C++/C/ObjC projects, header search paths are
    /// propagated so that / indexing, code completion, and other semantic
    /// features work.
    let generateTransitiveXcodeTargets: Bool

    /// Enable generation of transitive Xcode schemes
    /// Defaults to `true`
    let generateXcodeSchemes: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paths = try container.decode(
                [String]?.self, forKey: .paths)

        buildBazelPlatformOptions = try? container.decode(
                [String: [String]].self, forKey: .paths)

        generateXcodeSchemes = (try? container.decode(
                Bool.self, forKey: .generateXcodeSchemes)) ?? true

        generateTransitiveXcodeTargets = (try? container.decode(
                Bool.self, forKey: .generateTransitiveXcodeTargets)) ?? true
    }
}

struct XCHammerConfig: Codable {
    /// Labels for all targets. 
    /// Transitve dependencies are converted into targets unless excluded by
    /// source filters.
    let targets: [String]

    /// Optional config for each target
    let targetConfig: [String: XCHammerTargetConfig]?

    /// All of the projects keyed by a config
    let projects: [String: XCHammerProjectConfig]

    func getTargetConfig(for label: String) -> XCHammerTargetConfig? {
        return targetConfig?[label]
    }

    static let empty: XCHammerConfig = XCHammerConfig(targets: [], targetConfig: [:], projects: [:])
}

