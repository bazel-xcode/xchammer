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

