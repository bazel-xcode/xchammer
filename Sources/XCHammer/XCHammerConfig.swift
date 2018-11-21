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
import PathKit

struct XCHammerTargetConfig: Codable {
    /// Scheme runtime command line arguments for each target
    let commandLineArguments: [String]?
    
    /// Scheme runtime environment Variables for each target
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
   
    /// Like XCHammerProjectConfig.xcconfigOverrides but for targets
    /// Target configs replace project configs
    let xcconfigOverrides: [String: String]?
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

    /// xcconfig file overrides keyed by Xcode config name
    /// 
    /// Generally, "build settings", importantly compiler options, are
    /// propagated to Xcode by XCHammer automatically.
    ///
    /// Generally, the default XCHammer Xcode build should match Bazel by
    /// default ( if not it's a bug )
    /// 
    /// _Why would an xcconfig be needed then?_
    ///
    /// - Xcode's default settings may need to be overridden to make the Bazel
    ///   build the same as the Xcode one.
    ///
    /// - Some Xcode idioms don't exist in Bazel and a user may need to control
    ///   such options e.g. static analyzer settings.
    ///
    /// - It may be useful to have divergence in Bazel -> Xcode settings for
    ///   some local development tasks.
    ///
    /// - Some people are more comfortable changing XCConfigs and they want to
    ///   change them locally. 
    ///  
    /// note: by setting this, all diagnostic options are filtered out.
    /// note: config names are case sensitive here e.g. 'Debug'
    let xcconfigOverrides: [String: String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paths = try container.decodeIfPresent(
                [String]?.self, forKey: .paths) as? [String]

        buildBazelPlatformOptions = try container.decodeIfPresent(
                [String: [String]].self, forKey: .buildBazelPlatformOptions)

        generateXcodeSchemes = (try container.decodeIfPresent(
                Bool.self, forKey: .generateXcodeSchemes)) ?? true

        generateTransitiveXcodeTargets = (try container.decodeIfPresent(
                Bool.self, forKey: .generateTransitiveXcodeTargets)) ?? true

        xcconfigOverrides = (try container.decodeIfPresent(
                [String: String].self, forKey: .xcconfigOverrides)) ?? nil

    }
}

struct XCHammerConfig: Codable {
    /// Labels for all targets. 
    /// Transitve dependencies are converted into targets unless excluded by
    /// source filters.
    let targets: [String]

    /// Optional config for each target keyed by Bazel Label
    let targetConfig: [String: XCHammerTargetConfig]?

    /// All of the projects keyed by Project name
    let projects: [String: XCHammerProjectConfig]

    /// A metrics executable.
    /// XCHammer pipes metrics to this executable in the background to track
    /// generation times. Additionally, Xcode schemes are setup to log build
    /// times.
    ///
    /// @note It supports the statsd format.
    /// To write to statsd on localhost, simply provide a
    /// `metricsExecutable` via nc
    /// nc -w1 localhost 1337
    let metricsExecutable: String?

    func getTargetConfig(for label: String) -> XCHammerTargetConfig? {
        return targetConfig?[label]
    }

    static let empty: XCHammerConfig = XCHammerConfig(targets: [], targetConfig:
            [:], projects: [:], metricsExecutable: nil)
}

enum XCHammerConfigValidationError : Error {
    case invalidXCConfig(String)
}

/// Validate an XCHammerConfig in the context of a WORKSPACE
func validate(config: XCHammerConfig, workspaceRootPath: Path) throws -> Bool {
    /// TODO: Validate that full labels are passed in
    func validateXCConfigInput(overrides: [String: String]) throws {
        try overrides.forEach {
            k, v in
            let path = workspaceRootPath + Path(v)
            if !path.isFile {
                throw XCHammerConfigValidationError.invalidXCConfig(v)
            }
        }
    }
    try config.projects.forEach {
        projectName, project in
        if let overrides = project.xcconfigOverrides {
            try validateXCConfigInput(overrides: overrides)
        }
    }
    try config.targetConfig?.forEach {
        targetName, target in
        if let overrides = target.xcconfigOverrides {
            try validateXCConfigInput(overrides: overrides)
        }
    }

    return true
}


