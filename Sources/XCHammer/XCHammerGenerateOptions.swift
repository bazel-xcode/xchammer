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

import PathKit

public struct XcodeProjectRuleInfo: Codable {
    /// A template for exec root 
    let execRoot: String

    let tulsiinfos: [String]

    /// Bazel targets that reference the underlying project
    let bazelTargets: [String]
}

struct XCHammerGenerateOptions {
    let workspaceRootPath: Path

    let outputProjectPath: Path

    let bazelPath: Path

    /// The tulsi config used in the aspect
    let configPath: Path

    let config: XCHammerConfig

    let xcworkspacePath: Path?

    /// Info from the xcode_project rule
    let xcodeProjectRuleInfo: XcodeProjectRuleInfo?

    var workspaceEnabled: Bool {
        return xcworkspacePath != nil
    }

    var pathsSet: Set<String> {
        let paths = config.projects[projectName]?.paths ?? ["**"]
        return Set(paths)
    }

    var projectName: String {
        return outputProjectPath.lastComponentWithoutExtension
    }

    var projectConfig: XCHammerProjectConfig? {
        return config.projects[projectName]
    }
}

