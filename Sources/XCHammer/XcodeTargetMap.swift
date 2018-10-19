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
import TulsiGenerator
import ProjectSpec
import xcproj

/// Return flattened inner entries
func flattenedInner(targetMap: XcodeTargetMap) -> [XcodeTarget] {
    return targetMap.allTargets
        .filter(shouldFlatten)
        .flatMap { $0.unfilteredDependencies }
        .filter { $0.type.contains("application") == false }
        .filter { !$0.label.value.hasPrefix("//Vendor") }
}

func alwaysIncludePathPredicate(_ path: String) -> Bool {
    return true
}

/// Return a predicate that determines if a file should be included or not.
/// We can use this function to filter based on user input.
func makePathFiltersPredicate(_ paths: Set<String>) -> (String) -> Bool {
    let recursiveFilters = Set<String>(paths.filter({ $0.hasSuffix("**") }).map() {
        String($0[..<$0.index($0.endIndex, offsetBy: -2)])
    })

    func includePath(_ path: String) -> Bool {
        if paths.contains(path) {
            return true
        }
        let dir = (path as NSString).deletingLastPathComponent
        if paths.contains(dir) { 
            return true
        }

        // We don't normalize paths, so check for both terminated and non
        // terminated
        let terminatedDir = dir + "/"
        if paths.contains(terminatedDir) {
            return true
        }
        for filter in recursiveFilters {
            if terminatedDir.hasPrefix(filter) {
                return true
            }
        }
        return false
    }

    return includePath
}


/// Get all the tests
func allTests(for xcodeTarget: XcodeTarget, map targetMap: XcodeTargetMap) -> [String] {
    guard xcodeTarget.xcType != nil else {
        return []
    }

    switch xcodeTarget.extractProductType() {
        case .some(XcodeTarget.ProductType.UIUnitTest),
             .some(XcodeTarget.ProductType.UnitTest):
            return [xcodeTarget.xcTargetName]
    default:
        let testEntries = targetMap.includedTargets.filter { $0.xcType?.contains("-test") ?? false }
        return testEntries.map { $0.xcTargetName }
    }
}

extension Sequence where Element == Bool {
    func any() -> Bool {
        return filter { $0 }.count > 0
    }
}

func dirname(_ path: String) -> String {
    return Path(path).parent().string
}

public class XcodeTargetMap {
    public let ruleEntryMap: RuleEntryMap
    private let genOptions: XCHammerGenerateOptions

    private var labelToTargets = [BuildLabel: [XcodeTarget]]()

    private var internalTargets = [XcodeTarget]()

    public var allTargets: [XcodeTarget] {
        return internalTargets
    }

    init (entryMap: RuleEntryMap, genOptions: XCHammerGenerateOptions) {
        ruleEntryMap = entryMap
        self.genOptions = genOptions
        entryMap.allRuleEntries.forEach {
            print("ENTRY", $0)
            let xcodeTarget = XcodeTarget(ruleEntry: $0, map: self, genOptions:
                    genOptions)
            print("TARGET", xcodeTarget.label)
            insert(xcodeTarget: xcodeTarget)
        }
    }

    private func insert(xcodeTarget: XcodeTarget) {
        internalTargets.append(xcodeTarget)

        let label = xcodeTarget.label
        guard var entries = labelToTargets[label] else {
            labelToTargets[label] = [xcodeTarget]
            return
        }
        entries.append(xcodeTarget)
        labelToTargets[label] = entries
    }

    public func anyXcodeTarget(withBuildLabel buildLabel: BuildLabel) -> XcodeTarget? {
        guard let targets = labelToTargets[buildLabel] else {
            return nil
        }
        return targets.last
    }

    public func xcodeTarget(buildLabel: BuildLabel, depender: XcodeTarget) -> XcodeTarget? {
        guard let deploymentTarget = depender.deploymentTarget else {
            return anyXcodeTarget(withBuildLabel: buildLabel)
        }
        return xcodeTarget(buildLabel: buildLabel, deploymentTarget: deploymentTarget)
    }

    /// Returns a XcodeTarget with the given buildLabel and deploymentTarget.
    public func xcodeTarget(buildLabel: BuildLabel, deploymentTarget:
            TulsiGenerator.DeploymentTarget) -> XcodeTarget? {
        guard let targets = labelToTargets[buildLabel] else {
            return nil
        }
        guard !targets.isEmpty else {
            return nil
        }

        // If there's only one, we just assume that it's right.
        if targets.count == 1 {
            return targets.first
        }
        for xcodeTarget in targets {
            if deploymentTarget == xcodeTarget.deploymentTarget {
                return xcodeTarget
            }
        }
        return targets.last
    }

    public func targets(buildLabel: BuildLabel) -> [XcodeTarget] {
        guard let targets = labelToTargets[buildLabel] else {
            return [XcodeTarget]()
        }
        return targets
    }

    public lazy var includedTargets: [XcodeTarget] = {
        let pathsPredicate = makePathFiltersPredicate(self.genOptions.pathsSet)
        return self.allTargets.filter { includeTarget($0, pathPredicate: pathsPredicate) }
    }()
}

