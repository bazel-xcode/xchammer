//
//  XCHammerGenerateOptions.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import PathKit

struct XCHammerGenerateOptions {
    let workspaceRootPath: Path

    let outputProjectPath: Path

    let bazelPath: Path

    /// The tulsi config used in the aspect
    let configPath: Path

    let config: XCHammerConfig

    let xcworkspacePath: Path?

    let generateBazelTargets: Bool

    var workspaceEnabled: Bool {
        return xcworkspacePath != nil
    }

    var pathsSet: Set<String> {
        let paths = config.projects[projectName]?.paths ?? []
        return Set(paths)
    }

    var projectName: String {
        return outputProjectPath.lastComponentWithoutExtension
    }
}


