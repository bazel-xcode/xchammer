//
//  TulsiHooks.swift
//  XCHammer
//
//  Created by Brandon Kase on 10/27/17.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import TulsiGenerator
import PathKit

enum TulsiHooks {
    static func emitRuleEntryMap(labels: [BuildLabel], bazelPath: Path,
            workspaceRootPath: Path) throws ->
        RuleEntryMap {
        let ungeneratedProjectName = "Some"
        let config = TulsiGeneratorConfig(projectName: ungeneratedProjectName,
                buildTargetLabels: labels,
                pathFilters: Set(),
                additionalFilePaths: [],
                options: TulsiOptionSet(),
                bazelURL: TulsiParameter(value: bazelPath.url,
                    source: .options)
                )
        let ruleEntryMap = try TulsiRuleEntryMapExtractor.extract(config:
                config, workspace: workspaceRootPath.url)
        return ruleEntryMap
    }
}
