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
// limitations under the License.import Foundation

import Foundation

// TODO: Use Dictionary(_:uniqueingKeysWith) if this is on Swift 4
extension Dictionary {
    static func from<S: Sequence>(_ tuples: S) -> Dictionary where S.Iterator.Element == (Key, Value) {
        return tuples.reduce([:]) { acc, b in
            var mut = acc
            mut[b.0] = b.1
            return mut
        }
    }
}

