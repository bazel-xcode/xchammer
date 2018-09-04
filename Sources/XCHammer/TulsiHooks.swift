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
import PathKit

enum TulsiHooks {
    static func getWorkspaceInfo(labels: [BuildLabel], bazelPath: Path,
            workspaceRootPath: Path) throws ->
        XCHammerBazelWorkspaceInfo {
        let ungeneratedProjectName = "Some"
        let config = TulsiGeneratorConfig(projectName: ungeneratedProjectName,
                buildTargetLabels: labels,
                pathFilters: Set(),
                additionalFilePaths: [],
                options: TulsiOptionSet(),
                bazelURL: TulsiParameter(value: bazelPath.url,
                    source: .options))
        return try TulsiRuleEntryMapExtractor.extract(config:
                config, workspace: workspaceRootPath.url)
    }
}
