//
//  XCHammerConfig.swift
//  XCHammer
//
//  Created by Jerry Marino on 11/14/17.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation

struct XCHammerTargetConfig: Codable {
    /// Command line arguments for each target
    let commandLineArguments: [String]?
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

