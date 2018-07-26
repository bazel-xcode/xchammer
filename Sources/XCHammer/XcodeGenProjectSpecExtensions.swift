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
import ProjectSpec

extension ProjectSpec.Dependency : Hashable {
    public var hashValue: Int {
        return reference.hashValue
    }
}

extension ProjectSpec.TargetSource : Hashable {
    init(path: String, compilerFlags: [String]? = []) {
        self.init(path: path, name: nil, compilerFlags: compilerFlags
                ?? [])
    }
    public var hashValue: Int {
        return path.hashValue
    }
}

extension ProjectSpec.BuildScript {
    init(path: String?, script: String, name: String? = nil) {
        self.init(script: .script(script), name: name, inputFiles: [],
                outputFiles: [], shell: nil, runOnlyWhenInstalling: false)
    }
}

