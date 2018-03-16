//
//  XCHammerAsset.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

/// Assets written into the project.

import PathKit

enum XCHammerAsset: String {
    /// An empty .m file
    case stubImp = "Stub.m"

    /// A code signing script used for Ad-Hoc code signing
    case codesigner = "codesigner.sh"
    
    /// A higher-order bash script for command retries on failure
    /// Bazel's cache is invalidated if command fails the first time
    /// Assumes bazel is the first parameter
    case retry = "retry.sh"

    /// Code generated build file
    case buildFile = "BUILD"

    case updateScript = "updateXcodeProj.sh"

    /// Bazel extensions file. Contains rules to export entitlements from
    /// `rules_apple`
    case bazelExtensions = "Hammer.bzl"

    case genLog = "HammerLog.txt"

    /// This file is used to track the status of XCHammer and is updated when we
    /// successfully run. Do not use this for anything else, as it is not part
    /// the Xcode project and is unstable.
    case genStatus = "genStatus"

    func getPath() -> String {
        return "XCHammerAssets/" + self.rawValue
    }

    /// Project specific assets are written to __XCODE_PROJECT_/XCHammerAssets
    /// Ideally we should just write all assets under this path. Today assets
    /// are not distrubuted with XCHammer so fix that first.
    func getPath(underProj xcodeProjPath: Path) -> String {
        return xcodeProjPath.string + "/" + getPath()
    }
}

