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
import PathKit
import Result

private func relative(from base: Path) -> (Path) -> Path {
    return { path in
        Path(path.normalize().string.replacingOccurrences(of: "\(base.normalize().string)/", with: ""))
    }
}

let regex = try! NSRegularExpression(pattern: "", options: [])

private func processIpaExn(builtProductsDir: Path, codesigningFolderPath: Path) throws {
    // copy bundle to codesigning folder
    try (try builtProductsDir.children())
        .filter { $0.extension == "bundle" }
        .map(relative(from: builtProductsDir))
        .forEach {
            let oldPath = builtProductsDir + $0
            let path = codesigningFolderPath + $0

            let components = path.components
            if let bundleComponentIdx = (components.firstIndex { $0.contains("_Bundle_") }), path.extension == "bundle" {
                let component = components[bundleComponentIdx]
                let newComponent = component.components(separatedBy: "_Bundle_")[1]

                let prefix = components[components.startIndex ..< bundleComponentIdx]
                let suffix = components[bundleComponentIdx + 1 ..< components.endIndex]

                let correctPath = Path((prefix + [newComponent] + suffix).joined(separator: Path.separator))

                if correctPath.exists {
                    try correctPath.delete()
                }
                try oldPath.copy(correctPath)
            }
        }
}

func processIpa(builtProductsDir: Path, codesigningFolderPath: Path) -> Result<(), CommandError> {
    do {
        try processIpaExn(builtProductsDir: builtProductsDir, codesigningFolderPath: codesigningFolderPath)
        return .success(())
    } catch {
        return .failure(.swiftException(error))
    }
}
