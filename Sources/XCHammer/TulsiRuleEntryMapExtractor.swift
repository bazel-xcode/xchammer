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
import TulsiGenerator

public struct XCHammerBazelWorkspaceInfo {
    public let bazelExecRoot: String
    public let ruleEntryMap: RuleEntryMap
}

public enum TulsiRuleEntryMapExtractor {
    public static func extract(config: TulsiGeneratorConfig, workspace: URL)
        throws -> XCHammerBazelWorkspaceInfo {
        let bundle = Bundle.main

        let extractor = BazelWorkspaceInfoExtractor(bazelURL: config.bazelURL,
                workspaceRootURL: workspace, localizedMessageLogger:
                LocalizedMessageLogger(bundle: bundle))

        let execRoot = extractor.bazelExecutionRoot
        let features = BazelBuildSettingsFeatures.enabledFeatures(options:
                config.options)

        let ruleEntryMap = try extractor.ruleEntriesForLabels(
                config.buildTargetLabels, startupOptions:
                config.options[.BazelBuildStartupOptionsDebug],
                extraStartupOptions: config.options[.ProjectGenerationBazelStartupOptions], buildOptions:
                config.options[.BazelBuildOptionsDebug], compilationModeOption:
                config.options[.ProjectGenerationCompilationMode],
                platformConfigOption:
                config.options[.ProjectGenerationPlatformConfiguration],
                prioritizeSwiftOption: config.options[.ProjectPrioritizesSwift],
                use64BitWatchSimulatorOption: config.options[.Use64BitWatchSimulator],
                features: features)
        return XCHammerBazelWorkspaceInfo(bazelExecRoot: execRoot, ruleEntryMap:
                ruleEntryMap)
    }
}

