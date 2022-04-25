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
import XcodeProj
import ShellOut

private func shouldPropagateDeps(forTarget xcodeTarget: XcodeTarget) -> Bool {
    if xcodeTarget.genOptions.workspaceEnabled {
        return xcodeTarget.needsRecursiveExtraction
    }
    return true
}

/// Return XCConfig files
private func getXCConfigFiles(for xcodeTarget: XcodeTarget) -> [String: String] {
    let genOptions = xcodeTarget.genOptions
    let targetConfig = XcodeTarget.getTargetConfig(for: xcodeTarget)
    if let overrides = targetConfig?.xcconfigOverrides ?? genOptions.projectConfig?.xcconfigOverrides {
        return Dictionary.from(overrides.map {
            k, v in
            let path = genOptions.workspaceRootPath + Path(v)
            return (k, (path.string))
        })
    }
    return [String: String]()
}

let AppIconSet = "appiconset"

let DirectoriesAsFileSuffixes: [String] = [
    "app",
    "appex",
    "bundle",
    "framework",
    "octest",
    "xcassets",
    "xcodeproj",
    "xcdatamodel",
    "xcdatamodeld",
    "xcmappingmodel",
    "xctest",
    "xcstickers",
    "xpc",
    "scnassets",
    "lproj",
]

func isBundleLibrary(_ ruleType: String) -> Bool {
    // TODO: Remove deprecated rule
    return ruleType == "objc_bundle_library" || ruleType == "apple_resource_bundle"
}

func isBundle(_ ruleType: String) -> Bool {
    // TODO: Remove deprecated rule
    return ruleType == "objc_bundle" || ruleType == "apple_bundle_import"
}

func includeTarget(_ xcodeTarget: XcodeTarget, pathPredicate: (String) -> Bool) -> Bool {
    guard let buildFilePath = xcodeTarget.buildFilePath else {
        return false
    }

    guard pathPredicate(buildFilePath) else {
        return false
    }
    if xcodeTarget.type == "swift_runtime_linkopts" {
        return false
    }
    if xcodeTarget.type == "apple_framework_packaging" {
        return true
    }
    /*
    if xcodeTarget.label.value.hasSuffix("_swift") ||
    xcodeTarget.label.value.hasSuffix("_objc") {
        return false
    }*/
    if shouldPropagateDeps(forTarget: xcodeTarget) {
        return true
    }

    if isBundleLibrary(xcodeTarget.type) {
        return true
    }

    // Skip targets without implementations
    let impls = (xcodeTarget.sourceFiles + xcodeTarget.nonARCSourceFiles)
        .map { $0.subPath }
        .filter { !$0.hasSuffix(".modulemap") && !$0.hasSuffix(".hmap") && !$0.hasSuffix(".h") }
    if impls.count == 0 {
        return false
    }

    guard let _ = xcodeTarget.xcType else {
        return false
    }
    return true
}

// Traversal predicates
private let stopAfterNeedsRecursive: TraversalTransitionPredicate<XcodeTarget> = TraversalTransitionPredicate { $0.needsRecursiveExtraction ? .justOnceMore : .keepGoing }
private let stopAtBundles: TraversalTransitionPredicate<XcodeTarget> = TraversalTransitionPredicate { isBundleLibrary($0.type) ? .stop : .keepGoing }

let XCHammerIncludesSRCRoot = "$(SRCROOT)/xchammer-includes/x/x/"
let XCHammerIncludes = "xchammer-includes/x/x/"

// __BAZEL_GEN_DIR__ is a custom toolchain make variable
// resolve that to $(SRCROOT)/bazel-genfiles.
// TODO: remove this when it works in every case in Bazel and is no longer used
func subBazelMakeVariables(_ str: String, useSRCRoot: Bool = false) -> String {
    let sub = useSRCRoot ? XCHammerIncludesSRCRoot : XCHammerIncludes
    let output = str.replacingOccurrences(of: "__BAZEL_GEN_DIR__", with:
        sub).replacingOccurrences(of: "$(GENDIR)", with: sub)
    return subTulsiIncludes(output, useSRCRoot: useSRCRoot)
}

/// Tulsi injects this into strings in a few places
func subTulsiIncludes(_ str: String, useSRCRoot: Bool = false) -> String {
    let sub = useSRCRoot ? XCHammerIncludesSRCRoot : XCHammerIncludes
    return str.replacingOccurrences(of: "bazel-tulsi-includes/x/x/", with: sub)
}

public class XcodeTarget: Hashable, Equatable {
    private let ruleEntry: RuleEntry

    fileprivate let genOptions: XCHammerGenerateOptions

    // Memory semantic hack
    private weak var weakTargetMap: XcodeTargetMap?
    fileprivate var targetMap: XcodeTargetMap {
        return weakTargetMap!
    }

    init (ruleEntry: RuleEntry, map targetMap: XcodeTargetMap, genOptions:
            XCHammerGenerateOptions) {
        self.ruleEntry = ruleEntry
        self.weakTargetMap = targetMap
        self.genOptions = genOptions
    }


    public static func getTargetConfig(for xcodeTarget: XcodeTarget) -> XCHammerTargetConfig? {
        let genOptions = xcodeTarget.genOptions
        if let targetConfig = genOptions.config.getTargetConfig(for:
            xcodeTarget.label.value) {
            return targetConfig
        }

        // The target config may propagate to the internal binary when using dep
        // configs.
        if xcodeTarget.type == "ios_application" {
            let label = xcodeTarget.label.value + ".__internal__.apple_binary"
            return genOptions.config.getTargetConfig(for: label)
        }
        return nil
    }

    public var label: BuildLabel {
        return ruleEntry.label
    }

    public var type: String {
        return ruleEntry.type
    }

    public var hashValue: Int {
        return ruleEntry.hashValue
    }

    public func equals(_ other: XcodeTarget) -> Bool {
        return ruleEntry == other.ruleEntry
    }

    // MARK : RuleEntry helpers

    public var deploymentTarget: TulsiGenerator.DeploymentTarget? {
        return ruleEntry.deploymentTarget
    }

    fileprivate var linkedTargetLabels: Set<BuildLabel> {
        return ruleEntry.linkedTargetLabels
    }

    fileprivate var attributes: [RuleEntry.Attribute: AnyObject] {
        return ruleEntry.attributes
    }

    fileprivate var artifacts: [BazelFileInfo] {
        return ruleEntry.artifacts
    }

    fileprivate var defines: [String]? {
        return ruleEntry.objcDefines
    }

    fileprivate var sourceFiles: [BazelFileInfo] {
        return ruleEntry.sourceFiles
    }

    fileprivate var nonARCSourceFiles: [BazelFileInfo] {
        return ruleEntry.nonARCSourceFiles
    }

    fileprivate var includePaths: [RuleEntry.IncludePath]? {
        return ruleEntry.includePaths
    }

    fileprivate var dependencies: Set<BuildLabel> {
        return ruleEntry.dependencies
    }

    fileprivate var extensions: Set<BuildLabel> {
        return ruleEntry.extensions
    }

    fileprivate var frameworkImports: [BazelFileInfo] {
        return ruleEntry.frameworkImports
    }

    fileprivate var weakDependencies: Set<BuildLabel> {
        return ruleEntry.weakDependencies
    }

    fileprivate var buildFilePath: String? {
        return ruleEntry.buildFilePath
    }

    fileprivate var bundleID: String? {
        return ruleEntry.bundleID
    }

    fileprivate var bundleName: String? {
        return ruleEntry.bundleName
    }

    fileprivate var extensionBundleID: String? {
        return ruleEntry.extensionBundleID
    }

    fileprivate var extensionType: String? {
        return ruleEntry.extensionType
    }

    lazy var isExtension: Bool = {
        return self.xcType?.contains("app-extension") ?? false
    }()

    lazy var needsRecursiveExtraction: Bool = {
        let type = self.xcType
        let needsRecursiveTypes: Set<String> = [
            "application",
            "app-extension",
            "apple_ui_test",
            "ios_ui_test"
        ]
        let value = self.shouldFuseDirectDeps || (
            type.map { needsRecursiveTypes.contains($0) } ?? false
        )
        return value
    }()

    lazy var xcTargetName: String = {
        let numberOfEntries = self.targetMap.includedTargets
                .filter { $0.label == self.label }.count
        let deploymentSuffix = (numberOfEntries > 1) ? self.deploymentTarget.map { "\($0.platform)-\($0.osVersion)" } : nil

        // FIXME: Add uncolliding naming convention
        // For now, we'll assume that all projects in the target have
        // an uncolliding name, unless targets are Vendored
        guard self.label.packageName!.contains("Vendor") == true else {
            return [self.label.targetName!, deploymentSuffix].compactMap{ $0 }.joined(separator: "-")
        }

        // We can't rely on target name in the global scope
        // Note: this basic logic doesn't work in 100% of cases, like when
        // a pod has a different package name than the target. ( Texture-AsycDisplayKit )
        let lastPackageComponent = self.label.packageName!.split(separator: "/").last!
        if lastPackageComponent == self.label.targetName! {
            return [String(lastPackageComponent), deploymentSuffix].compactMap { $0 }.joined(separator: "-")
        }
        return [String(lastPackageComponent), self.label.targetName!, deploymentSuffix].compactMap { $0 }.joined(separator: "-")
    }()

    func getXCSourceRootAbsolutePath(for fileInfo: BazelFileInfo) -> String {
        switch fileInfo.targetType {
        case .sourceFile:
            return "$(SRCROOT)/" + resolveExternalPath(for: fileInfo.subPath)
        case .generatedFile:
            return "$(SRCROOT)/bazel-genfiles/" + fileInfo.subPath
        }
    }

    func getRelativePath(for fileInfo: BazelFileInfo, useTulsiPath: Bool = false) -> String {
        switch fileInfo.targetType {
        case .sourceFile:
            return resolveExternalPath(for: fileInfo.subPath)
        case .generatedFile:
            return XCHammerIncludes + resolveExternalPath(for: fileInfo.subPath)
        }
    }

    func resolveExternalPath(for path: String) -> String {
        if path.hasPrefix("external/") {
            return path.replacingOccurrences(of: "../", with: "external/")
        } else if path.hasPrefix("../") {
            return "external" + String(path.dropFirst().dropFirst())
        }
        return path
    }

    lazy var unfilteredDependencies: [XcodeTarget] = {
        let unwrapSuffixes: Set<String> = [
            ".apple_binary",
            "_test_bundle",
            "_test_binary",
            //"_objc",
            //"_swift",
            "middleman",
        ]

        return self.dependencies
            .compactMap { self.targetMap.xcodeTarget(buildLabel: $0, depender: self) }
            .flatMap { xcodeTarget in
                (unwrapSuffixes.map { xcodeTarget.label.value.hasSuffix($0) }.any()) ?
                    xcodeTarget.unfilteredDependencies :
                    [xcodeTarget]
            }
    }()

    private static func isHeaderLike(path: String) -> Bool {
        // Reference: XcodeGenKit/SourceGenerator.swift
        return path.hasSuffix(".h") ||
            path.hasSuffix(".hpp") ||
            path.hasSuffix(".hh") ||
            path.hasSuffix(".ipp") ||
            path.hasSuffix(".tpp") ||
            path.hasSuffix(".hxx") ||
            path.hasSuffix(".def")
    }

    lazy var xcCompileableSources: [ProjectSpec.TargetSource] = {
        let sourceFiles = self.sourceFiles
            .filter { !$0.subPath.hasSuffix(".modulemap") && !$0.subPath.hasSuffix(".hmap") }
            .map { fileInfo -> ProjectSpec.TargetSource in
                let path = self.getRelativePath(for: fileInfo)
                let phase = XcodeTarget.isHeaderLike(path: path) ?
                    TargetSource.BuildPhase.headers : nil
                return ProjectSpec.TargetSource(path: path, buildPhase: phase,
                        headerVisibility:
                        TargetSource.HeaderVisibility.`project`)
            }
        let nonArcFiles = self.nonARCSourceFiles
            .map {
                fileInfo -> ProjectSpec.TargetSource in
                let path = self.getRelativePath(for: fileInfo)
                let phase = XcodeTarget.isHeaderLike(path: path) ?
                    TargetSource.BuildPhase.headers : nil
                return ProjectSpec.TargetSource(path: path,
                         compilerFlags: ["-fno-objc-arc"],
                        buildPhase: phase, headerVisibility:
                        TargetSource.HeaderVisibility.`project`)
            }


        let stubAsset = self.settings.swiftVersion == nil ?  XCHammerAsset.stubImp : XCHammerAsset.stubImpSwift
        let all: [ProjectSpec.TargetSource] = nonArcFiles + (sourceFiles.filter { !$0.path.hasSuffix("h") }.count > 0 ?
            sourceFiles :
            [ProjectSpec.TargetSource(path: stubAsset.getPath(underProj:
                    self.genOptions.outputProjectPath), compilerFlags: ["-x objective-c", "-std=gnu99"])]
        )
        let s: Set<ProjectSpec.TargetSource> = Set(all)
        return Array(s)
    }()

    lazy var xcSources: [ProjectSpec.TargetSource] = {
        let s: Set<ProjectSpec.TargetSource> = Set(self.xcResources + self.xcBundles + self.xcCompileableSources)
        return Array(s)
    }()

    func transitiveTargets(map targetMap: XcodeTargetMap, predicate:
            TraversalTransitionPredicate<XcodeTarget> =
            TraversalTransitionPredicate<XcodeTarget>.empty, force: Bool = true) -> [XcodeTarget] {
        if !force && !needsRecursiveExtraction {
            return []
        }
        var visited: Set<XcodeTarget> = [self]

        var transitiveTargets: [XcodeTarget] = []
        var queue = unfilteredDependencies
        while let xcodeTarget = queue.first {
            queue.removeFirst()

            guard visited.insert(xcodeTarget).inserted else {
                continue
            }
            switch predicate.run(xcodeTarget) {
            case .stop:
                continue
            case .justOnceMore:
                transitiveTargets.append(xcodeTarget)
            case .keepGoing:
                transitiveTargets.append(xcodeTarget)
                if force || xcodeTarget.needsRecursiveExtraction {
                    queue.insert(contentsOf: xcodeTarget.unfilteredDependencies, at: 0)
                }
            }
        }

        return transitiveTargets
    }

    func makePathFiltersTransitionPredicate(paths: Set<String>) -> TraversalTransitionPredicate<XcodeTarget> {
        let pathPredicate = makePathFiltersPredicate(paths)
        return TraversalTransitionPredicate { xcodeTarget -> Transition in
            guard let buildFilePath = xcodeTarget.buildFilePath else {
                fatalError()
            }
            guard pathPredicate(buildFilePath) else {
                return .stop
            }
            return .keepGoing
        }
    }

    lazy var xcResources: [ProjectSpec.TargetSource] = {
        if self.needsRecursiveExtraction {
            let deps: [XcodeTarget] = ([self] +
                    self.transitiveTargets(map:
                        self.targetMap, predicate: stopAtBundles <>
                        stopAfterNeedsRecursive ))
                .filter { !$0.isEntitlementsDep }

            return Array(Set(deps.flatMap { $0.myResources }))
        } else {
            // FIXME: We naievely copy all resources
            return self.myResources
        }
    }()

    lazy var xcAdHocFiles: [String] = {
        let projectConfig = genOptions.config
                .projects[genOptions.projectName]
        // Include resources is ad-hoc files if they're not in a target
        let generateXcodeTargets = (projectConfig?.generateXcodeSchemes ?? true != false)
        let buildFile = [self.buildFilePath ?? ""]
        guard generateXcodeTargets == false else {
            return buildFile
        }
        return buildFile + self.xcBundles.map { $0.path } + self.xcResources.map { $0.path }
    }()

    // TODO: consider refactoring this code to return `BazelFileInfo`s if possible
    func pathsForAttrs(attrs: Set<RuleEntry.Attribute>) -> [Path] {
        return attrs.flatMap { attr in
            self.attributes[attr] as? [[String: Any]] ??
                (self.attributes[attr] as? [String: Any]).map{ [$0] } ??
                []
            }
        .filter { ($0["src"] as? Bool) ?? false }
        .compactMap { $0["path"] as? String }.map { Path($0) }
    }

    func isAllowableXcodeGenSource(path: Path) -> Bool {
        // These files are handled in other ways.
        return path.extension != "mobileprovision"
    }

    lazy var myResources: [ProjectSpec.TargetSource] = {
        let pathsPredicate = makeOptionalPathFiltersPredicate(self.genOptions)
        let resources: [ProjectSpec.TargetSource] = self.pathsForAttrs(attrs:
                [.launch_storyboard, .supporting_files])
            .filter(self.isAllowableXcodeGenSource(path:))
            .filter { pathsPredicate($0.string) }
            .compactMap { inputPath in
            let path = Path(self.resolveExternalPath(for: inputPath.string))
            let pathComponents = path.components
            if let specialIndex = (pathComponents.firstIndex { component in
                DirectoriesAsFileSuffixes.map { component.hasSuffix("." + $0) }.any()
            }) {
                let formattedPath =
                    Path(pathComponents[pathComponents.startIndex ...
                            specialIndex].joined(separator: Path.separator))
                if formattedPath.extension == "lproj" {
                    // TODO: Don't hardcode the parents for lproj
                    return ProjectSpec.TargetSource(path: formattedPath.parent().string, type: .group)
                } else {
                    return ProjectSpec.TargetSource(path: formattedPath.string)
                }
            } else {
                return ProjectSpec.TargetSource(path: path.string)
            }
        }

        let structuredResources: [ProjectSpec.TargetSource] =
            self.pathsForAttrs(attrs: [.structured_resources]).compactMap {
                resourcePath -> ProjectSpec.TargetSource? in
            guard let buildFilePath = self.buildFilePath else { return nil }
            let basePath = Path(buildFilePath).parent().normalize()
            // now we can recover the relative path provided inside the build files
            let buildFileRelativePath =
            Path(resourcePath.string.replacingOccurrences(of: basePath.string +
                        "/", with: ""))
            // the structured path is the first directory relative to the build file dir
            let structuredPath = basePath + Path(buildFileRelativePath.components[0])
            // structured resources are rendered as folder-references in Xcode
            return ProjectSpec.TargetSource(path: self.resolveExternalPath(for:
                structuredPath.string), compilerFlags: [], type: .folder)
        }

        // Normalize for Xcode
        // - dedupe
        // - frameworks shouldn't be injested as a resource or a source
        return Array(Set(resources + structuredResources))
            .filter { !$0.path.hasSuffix(".framework") }
             // FIXME: There is path issue with a subset of BUILD files.
            .filter { !$0.path.hasSuffix("BUILD") }
    }()

    func extractBuiltProductName() -> String {
        guard let productType = extractProductType() else {
            fatalError()
        }
        switch productType {
            case .Application:
            return xcTargetName + ".app"
            case .UnitTest, .UIUnitTest:
            return xcTargetName + ".xctest"
            case .AppExtension, .XPCService, .Watch1App, .Watch2App, .Watch1Extension, .Watch2Extension, .TVAppExtension, .IMessageExtension:
            return xcTargetName + ".appex"
            case .StaticLibrary:
            return xcTargetName
            case .Framework:
            return xcTargetName
            default:
            return "$(TARGET_NAME)"
        }
    }

    func extractLinkableBuiltProductName(map targetMap: XcodeTargetMap) -> String? {
        guard let productType = extractProductType() else {
            return nil
        }
        switch productType {
            case .StaticLibrary:
            return "lib" + xcTargetName + ".a"
            case .StaticFramework, .Framework:
            return xcTargetName
            default:
            return nil
        }
    }

    private static let librarySourceTypes = Set(["swift", "m", "mm", "cpp", "c", "cc", "S"])

    // Returns transitive linkable
    lazy var xcLinkableTransitiveDeps: Set<ProjectSpec.Dependency> = {
        // By traversing the dependency graph through `transitiveTargets` we
        // pick up many dependencies, that may or may not be on the linker
        // command line. Consider other ways to do this. For now, reject known
        // non legitimate dependency propagators.
        let linkablePredicate: TraversalTransitionPredicate<XcodeTarget> = TraversalTransitionPredicate {
            xcodeTarget -> Transition in
            guard xcodeTarget.type != "_headermap" else {
                return Transition.stop
            }
            if xcodeTarget.extractProductType() == nil {
                return Transition.stop
            }
            return xcodeTarget.needsRecursiveExtraction ? Transition.justOnceMore : Transition.keepGoing
        }

        let deps = self.transitiveTargets(map: self.targetMap, predicate:
                linkablePredicate, force: true)
            .flatMap { xcodeTarget -> [ProjectSpec.Dependency] in
                let projectConfig = xcodeTarget.genOptions.config
                            .projects[genOptions.projectName]

                let generateTransitiveXcodeTargets =
                            (projectConfig?.generateTransitiveXcodeTargets ?? true)
                guard generateTransitiveXcodeTargets else { return [] }

                // Focus - XcodeSchemes are disabled, and the target is not
                // included don't include it is a dependency.
                // under workspace mode, the latter code uses an implicit dep.
                let genOptions = self.genOptions
                if xcodeTarget.genOptions.workspaceEnabled == false,
                    (projectConfig?.generateXcodeSchemes ?? true) != true,
                    includeTarget(xcodeTarget, pathPredicate:
                        makePathFiltersPredicate(genOptions.pathsSet)) != true {
                    return []
                }

                let pathsPredicate = makeOptionalPathFiltersPredicate(genOptions)
                guard let linkableProductName =
                    xcodeTarget.extractLinkableBuiltProductName(map:
                            self.targetMap), includeTarget(xcodeTarget, pathPredicate:
                        pathsPredicate) else {
                    // either way, get the dependencies
                    return xcodeTarget.xcDependencies
                }

                guard let productType = xcodeTarget.extractProductType() else { return xcodeTarget.xcDependencies }

                switch productType {
                // Do not link static libraries that aren't going to exist.
                // These targets still need to be included in the project.
                case .StaticLibrary, .DynamicLibrary:

                    let compiledSrcs = (xcodeTarget.sourceFiles + xcodeTarget.nonARCSourceFiles)
                        .filter {
                       fileInfo in
                       let path = fileInfo.subPath
                       guard let suffix = path.components(separatedBy: ".").last else { return false }
                       return XcodeTarget.librarySourceTypes.contains(suffix)
                    }
                    if compiledSrcs.count == 0 {
                        return xcodeTarget.xcDependencies
                    }
                default:
                    break
                }

                if xcodeTarget.genOptions.workspaceEnabled
                        || xcodeTarget.type == "apple_static_framework_import"
                        || xcodeTarget.type == "apple_dynamic_framework_import"
                        || xcodeTarget.type == "ios_framework"
                        || xcodeTarget.type == "objc_import" {
                    // Dep's aren't really frameworks.
                    // The idea here is to drop these deps in "Link With Libs"
                    // phase, so that Xcode can implicitly resolve them
                    return [ProjectSpec.Dependency(type: .framework, reference: linkableProductName,
                            embed: xcodeTarget.isExtension)]
                        + xcodeTarget.xcDependencies
                } else {
                    // For some target types ( e.g. Swift static libs on Xcode
                    // 10.2 ) Xcode's implicit resolution doesn't seem to add a
                    // dependency on the Swift module
                    let productName = xcodeTarget.extractBuiltProductName()
                    return [ProjectSpec.Dependency(type: .target, reference: productName,
                            embed: xcodeTarget.isExtension)]
                        + xcodeTarget.xcDependencies
                }
            }
        return Set(deps)
    }()

    lazy var settings: XCBuildSettings = {
        let targetMap = self.targetMap
        let genOptions = self.genOptions
        func processDefines(defines: [String]) -> [String] {
            return defines
                .filter { !$0.hasPrefix("__TIME") }
                .filter { !$0.hasPrefix("__DATE") }
                .sorted()
                .map { "-D\($0)" }
        }

        func extractSwiftVersion() -> String? {
            // First respect swift language version if explicitly defined
            // This should be less common and i believe was only supported by old rules_apple rules
            if let version = self.attributes[.swift_language_version] as? String {
                return version
            }

            // Second look through the swiftcopts to see if `-swift-version <version>` has been specified
            if let coptsArray = self.attributes[.swiftc_opts] as? [String] {
                let versionOpt = coptsArray.filter { $0.hasPrefix("-swift-version") }.first
                let version = versionOpt.map { $0.split(separator: " ") }?.last.map(String.init)
                if version != nil {
                    return version
                }
            }

            // Lastly if we have a swift dependency and can't determine the version, ask swiftc
            if self.attributes[.has_swift_dependency] != nil || self.attributes[.has_swift_info] != nil {
                // We don't have a guarantee the format will always be the same but it's unlikely to change
                // ^^ I will regret these words (rmalik)
                return try? (ShellOut.shellOut(to: "xcrun swiftc -version | cut -d ' ' -f4")).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return nil
        }

        var settings = XCBuildSettings()
        self.attributes.keys.sorted(by: { $0.rawValue < $1.rawValue }).forEach { attr in
            let value = self.attributes[attr]!
            switch attr {
            case .copts:
                if let coptsArray = value as? [String] {
                    let processedOpts = coptsArray.enumerated().reduce(into: [String]()) {
                        accum, itr in
                        let (idx, opt) = itr
                        if opt == "-I." {
                             accum.append(opt)
                        } else if opt == "-index-store-path" || (idx > 0 &&
                            coptsArray[idx - 1] == "-index-store-path") {
                            return
                        } else if !opt.isEmpty {
                            accum.append(subBazelMakeVariables(opt, useSRCRoot: true))
                        }
                    }
                    settings.copts <>= processedOpts
                }
            case .compiler_defines:
                if let definesArray = value as? [String] {
                    let processedDefines = processDefines(defines: definesArray)
                    settings.copts <>= processedDefines
                }
            case .pch:
                if let pchDictionary = value as? [String: AnyObject] {
                    guard let pchPath = pchDictionary["path"] as? String else {
                        fatalError("Invalid PCH dictionary, missing `path`: \(pchDictionary)")
                    }
                    settings.pch <>= First("$(SRCROOT)/\(pchPath)")
                }
            case .enable_modules:
                settings.enableModules <>= (value as? Bool).map { First($0 ? "YES" : "NO") }
            case .supporting_files:
                settings.infoPlistFile <>= (value as? [[String: AnyObject]]).flatMap { $0.map { dict in
                    if let filePath = dict["path"] as? String,
                        Path(filePath).extension == "plist" {
                        return First("$(SRCROOT)/\(filePath)")
                    } else {
                        return nil
                    }
                }.reduce(nil, <>) }
            case .test_host:
                guard !value.hasPrefix("@"),
                    let entry = self.targetMap.anyXcodeTarget(withBuildLabel: BuildLabel(value as! String)) else {
                    break
                }
                let xcTargetName = entry.xcTargetName
                if self.type == "apple_ui_test" || self.type == "ios_ui_test" {
                    // USES_XCTRUNNER is set by Xcode automatically so we just need to set the test target name
                    settings.testTargetName <>= First(xcTargetName)
                } else {
                    settings.testHost <>= First("$(BUILT_PRODUCTS_DIR)/\(xcTargetName).app/\(xcTargetName)")
                    settings.bundleLoader <>= First("$(TEST_HOST)")
                }
            case .sdk_dylibs, .sdk_frameworks, .weak_sdk_frameworks:
                // These are implemented below
                break
            case .launch_storyboard, .structured_resources, .entitlements, .provisioning_profile:
                break // These attrs are not related to XCConfigs
            case .binary:
                break // Explicitly not handled since it is a implicit target we don't intend to handle
            case .swift_language_version,  .has_swift_dependency, .has_swift_info:
                break // Logic handled in extractSwiftVersion function since there is a logical order of determining SWIFT_VERSION
            case .swiftc_opts:
                if let coptsArray = value as? [String] {
                    let processedOpts = coptsArray.enumerated().reduce(into: [String]()) {
                        accum, itr in
                        let (idx, opt) = itr
                        if opt == "-I." {
                             accum.append(opt)
                        }  else if opt == "-index-store-path" || (idx > 0 &&
                            coptsArray[idx - 1] == "-index-store-path") {
                            return
                        } else if !opt.isEmpty {
                            accum.append(subBazelMakeVariables(opt, useSRCRoot: true))
                        }
                    }
                    settings.swiftCopts <>= processedOpts
                }
            default:
                print("TODO: Unimplemented attribute \(attr) \(value)")
            }
        }

        // Swift version
        settings.swiftVersion <>= extractSwiftVersion().map(First.init)

        // Product Name
        settings.productName <>= self.bundleName.map { First($0) }

        if settings.productName == nil, self.xcType != nil {
            settings.productName = First(self.extractBuiltProductName())
        }

        // Set the module name - this is needed for some use cases
        if let definedModuleName =  self.ruleEntry.moduleName {
            settings.moduleName = First(definedModuleName)
        } else {
            // Note: this needs to conform to the clang module spec. Assume that
            // a Bazel label would excpet for -
            let possiblyValidName = xcTargetName.replacingOccurrences(of: "-", with: "_")
            settings.moduleName = First(possiblyValidName)
        }

        // Product Bundle Identifier
        settings.productBundleId <>= self.bundleID.map { First($0) }

        // Set Header Search Paths
        if let headerSearchPaths = self.includePaths {
            settings.headerSearchPaths <>=
                OrderedArray(["$(inherited)"]) <>
                headerSearchPaths
                .foldMap { (path: String, isRecursive: Bool) in
                if isRecursive {
                    return ["$(SRCROOT)/\(path)/**"]
                } else if path != "." {
                    return ["$(SRCROOT)/\(subTulsiIncludes(path, useSRCRoot: false))"]
                } else {
                    return []
                }
            }
        }

        settings.headerSearchPaths <>=
                OrderedArray(["$(SRCROOT)/external/"])

        // Add copts for module maps
        settings.copts <>= self.ruleEntry.objCModuleMaps.map {
            "-fmodule-map-file=" + subBazelMakeVariables(getRelativePath(for: $0,
                useTulsiPath: true))
        }

        // Patch on inclusion of swift modules
        let transTargets = self.transitiveTargets(map: targetMap)
            .sorted(by: { $0.label < $1.label })
        let swiftModuleIncs: [String] = transTargets.compactMap {
            xcodeTarget in
            guard xcodeTarget.ruleEntry.moduleName != nil,
                xcodeTarget.type == "swift_library",
                let buildFilePath = xcodeTarget.buildFilePath else {
                return nil
            }

            let parts = buildFilePath.components(separatedBy: "/").dropLast()
            let xchammerIncludeDir  = XCHammerIncludes +  parts.joined(separator: "/")
            return "-I " + xchammerIncludeDir
        }
        settings.swiftCopts <>= swiftModuleIncs
        /*
        settings.swiftCopts <>= self.ruleEntry.objCModuleMaps.map {
            "-Xcc -fmodule-map-file=" + subBazelMakeVariables(getRelativePath(for: $0,
                useTulsiPath: true))
        }*/

        if let headerMap =  self.extractHeaderMap() {
            settings.swiftCopts <>= ["-Xcc -iquote -Xcc " + headerMap]
        }

        // Delegate warnings and error compiler options for targets that have a
        // xcconfig.
        let configs = getXCConfigFiles(for: self)

        settings.diagnosticFlags <>=  settings.copts.filter { $0.hasPrefix("-W") }
        if configs.keys.count > 0 {
            settings.copts = ["$(inherited)"] + settings.copts.filter { !$0.hasPrefix("-W") }
        }
        // Framework Search Paths
        settings.frameworkSearchPaths <>= ["$(inherited)",
            "$(PLATFORM_DIR)/Developer/Library/Frameworks"] <>
                OrderedArray(self.frameworkDependencies
                    .compactMap { dep in dep.reference }
            .map(dirname)
            .map { "$(SRCROOT)/\($0)" })

        let libraryDeps = self.extractLibraryDeps(map: targetMap)
        settings.librarySearchPaths <>= OrderedArray(libraryDeps.map(dirname))


        // Add defines as copts
        settings.copts <>= processDefines(defines: self.extractDefines(map: targetMap))

        if let moduleMapPath = self.extractModuleMap() {
            settings.moduleMapFile <>= First(moduleMapPath)
            settings.enableModules <>= First("YES")
        }

        settings <>= getDeploymentTargetSettings()

        // Code Signing
        settings.codeSigningRequired <>= First("NO")
        settings.codeSigningIdentity <>= First("")

        // Misc
        settings.onlyActiveArch <>= First("YES")
        // Fixes an Xcode "Upgrade to recommended settings" warning. Technically the warning only
        // requires this to be added to the Debug build configuration but as code is never compiled
        // anyway it doesn't hurt anything to set it on all configs.
        settings.enableTestability <>= First("YES")

        // Bazel sources are more or less ARC by default (the user has to use the special non_arc_srcs
        // attribute for non-ARC) so the project is set to reflect that and per-file flags are used to
        // override the default.
        settings.enableObjcArc <>= First("YES")

        if let appIconComponent = (self.pathsForAttrs(attrs: [.supporting_files]).flatMap { $0.components }.first { $0.hasSuffix(".\(AppIconSet)") }) {
            let appIcon: String = appIconComponent.replacingOccurrences(of: ".\(AppIconSet)", with: "")
            settings.appIconName <>= First(appIcon)
        } else {
            settings.appIconName <>= First("")
        }

        // Linker Flags (Frameworks, Weak Frameworks, ...)

        func getLibraryName(atPath path: String) -> String {
            guard let libName = path.components(separatedBy: "/").last?.components(separatedBy: ".").first else {
                fatalError()
            }
            let offsetIdx = libName.utf8.index(libName.utf8.startIndex, offsetBy: 3)
            return String(libName[offsetIdx ..< libName.utf8.endIndex])
        }


        let linkerLibOpts: OrderedArray<String> = self.needsRecursiveExtraction ? OrderedArray(libraryDeps.compactMap { value in
            "-l\(getLibraryName(atPath: value))"
        } + ["-ObjC"]) : []


        // We've got custom entitlements linking actions for simulator only
        let baseLDFlags = linkerLibOpts <>
        OrderedArray(self.SDKFrameworks.map { "-framework \($0)" }) <>
        OrderedArray(self.weakSDKFrameworks.map { "-weak_framework \($0)" }) <>
        OrderedArray(self.SDKDylibs.map { "-l\($0)" })
        settings.ldFlags <>= Setting(base: baseLDFlags,
                                       SDKiPhoneSimulator: baseLDFlags,
                                       SDKiPhone: nil)
        return settings
    }()

    func getDeploymentTargetSettings() -> XCBuildSettings {
        var settings = XCBuildSettings()
        // Set thes deployment target if available
        if let deploymentTgt = self.deploymentTarget {
            switch deploymentTgt.platform {
            case .ios:
                settings.iOSDeploymentTarget <>= First(deploymentTgt.osVersion)
                settings.sdkRoot <>= First("iphoneos")
                settings.targetedDeviceFamily <>= ["1", "2"]
            case .tvos:
                settings.tvOSDeploymentTarget <>= First(deploymentTgt.osVersion)
                settings.sdkRoot <>= First("appletvos")
                settings.targetedDeviceFamily <>= ["3"]
            case .watchos:
                settings.watchOSDeploymentTarget <>= First(deploymentTgt.osVersion)
                settings.sdkRoot <>= First("watchos")
                settings.targetedDeviceFamily <>= ["4"]
            case .macos:
                settings.macOSDeploymentTarget <>= First(deploymentTgt.osVersion)
                settings.sdkRoot <>= First("macosx")
            }
        }
        return settings
    }

    // ProductType and Map are different than Tulsi's
    enum ProductType: String {
        case StaticLibrary = "com.apple.product-type.library.static"
        case DynamicLibrary = "com.apple.product-type.library.dynamic"
        case Tool = "com.apple.product-type.tool"
        case Bundle = "com.apple.product-type.bundle"
        case Framework = "com.apple.product-type.framework"
        case StaticFramework = "com.apple.product-type.framework.static"
        case Application = "com.apple.product-type.application"
        case UnitTest = "com.apple.product-type.bundle.unit-test"
        case UIUnitTest = "com.apple.product-type.bundle.ui-testing"
        case InAppPurchaseContent = "com.apple.product-type.in-app-purchase-content"
        case AppExtension = "com.apple.product-type.app-extension"
        case XPCService = "com.apple.product-type.xpc-service"
        case Watch1App = "com.apple.product-type.application.watchapp"
        case Watch2App = "com.apple.product-type.application.watchapp2"
        case Watch1Extension = "com.apple.product-type.watchkit-extension"
        case Watch2Extension = "com.apple.product-type.watchkit2-extension"
        case TVAppExtension = "com.apple.product-type.tv-app-extension"
        case IMessageExtension = "com.apple.product-type.app-extension.messages"
    }

    lazy var shouldFuseDirectDeps: Bool = {
        //return self.xcType?.contains("-test") ?? false
        guard let type = self.xcType else { return false }
        // FIXME: this is used to determine fusing - need to make sure properly
        // fuse rules_ios: because of mixed-module output types. e.g.
        // $NAME_swift and $NAME_objc cannot both declare a .swiftmodule output
        // Could test for that, or even test for a tag
        return type.contains("-test") || type.contains("framework") ||
        type.contains("application")
    }()

    lazy var xcDependencies: [ProjectSpec.Dependency] = {
        /* FIXME: this needs better logic added to it
        guard self.frameworkImports.count > 0 else {
            return []
        }*/

        // TODO: Move this to xcLinkableTransitiveDeps
        let xcodeTargetDeps: [XcodeTarget] = self.dependencies.compactMap {
            depLabel in
            let depName = depLabel.value
            guard let target = self.targetMap.xcodeTarget(buildLabel: depLabel, depender: self) else {
                return nil
            }

            guard target.frameworkImports.count == 0 else {
                return nil
            }

            if target.extractProductType()  != nil {
                return nil
            }
            // FIXME: this should be an attribute in bazel build graph and or
            // convention to hide a target in Xcode, or align with fusing
            // predicate
            if depName.hasSuffix("linkopts")  {
                return nil
            }
            if depName.hasSuffix("_objc")  {
                return nil
            }
            if depName.hasSuffix("_swift")  {
                return nil
            }
            if depName.hasSuffix("_private_headers")  {
                return nil
            }

            //if depName.hasSuffix(".apple_binary")  {
            if false {
                let unwrappedDeps = target.dependencies
                for depEntry in unwrappedDeps {
                    // If it's an iOS app, strip out entitlements
                    if depEntry.value.hasSuffix("entitlements") {
                        continue
                    }

                    if let foundTarget = self.targetMap.xcodeTarget(buildLabel:
                            depEntry, depender: self), foundTarget.extractProductType() != nil {
                        return foundTarget
                    }
                }
            }
            return target
        }
        return xcodeTargetDeps
            .compactMap {
                xcodeTarget in
                guard targetMap.includedTargets.contains(xcodeTarget) else {
                    return nil
                }
                return ProjectSpec.Dependency(type: .target, reference:
                        xcodeTarget.xcTargetName, embed:
                        xcodeTarget.isExtension)
            } + self.frameworkDependencies
    }()

    lazy var frameworkDependencies: [ProjectSpec.Dependency] = {
        // Uwrap Framework deps to prevent having a Goofy framework target that doesn't do anything
        let shouldEmbed = self.attributes[.is_dynamic] as? Bool ?? false
        let frameworkImports = self.frameworkImports
            .map { fileInfo in fileInfo.fullPath }
            .map { ProjectSpec.Dependency(type: .framework, reference: $0, embed: shouldEmbed) }

        let childFrameworkImports = self.unfilteredDependencies.flatMap { entry in
            entry.frameworkDependencies
        }

        return Array(Set<ProjectSpec.Dependency>(frameworkImports + childFrameworkImports))
             .sorted(by: { $0.reference < $1.reference })
    }()

    lazy var xcType: String? = {
        let productType = self.extractProductType()
        return productType?.rawValue.replacingOccurrences(of: "com.apple.product-type.", with: "")
    }()

    /// MARK - Extraction helpers
    /// These helpers aren't memoized if they are called 1 time and cached

/**
  Bazel Convertible for the following rule
  export_ios_entitlements:
    name,
    entitlements,
    provisioning_profile,
    bundle_id
*/
    struct ExportEntitlements {
        let name: String
        let entitlements: String? // FileOrLabel
        let provisioningProfile: String? // FileOrLabel
        let bundleID: String

        func toBazel() -> String {
            let provisioningProfileEntry = provisioningProfile != nil ?
                "\"\(provisioningProfile!)\"" : "None"

            let entitlementsEntry = entitlements != nil ?
                "\"\(entitlements!)\"" : "None"
            return """
            export_entitlements(
              name = "\(name)",
              entitlements = \(entitlementsEntry),
              provisioning_profile = \(provisioningProfileEntry),
              bundle_id = "\(bundleID)",
              platform_type = \"ios\"
            )
            """
        }
    }

    func extractExportEntitlementRule(map targetMap: XcodeTargetMap) -> ExportEntitlements? {
        guard needsRecursiveExtraction,
              let bundleID = self.bundleID else {
            return nil
        }
        let label = BuildLabel(self.label.value + "_entitlements")
        guard let targetRule = targetMap.anyXcodeTarget(withBuildLabel: label) else {
            return nil
        }

        // This becomes //__PROJECT_NAME__.xcodeproj/XCHammerAssets:$targetName
        let targetName = label.asFullPBXTargetName!
        let entitlements = targetRule.attributes[.entitlements] as? String
        let provisioningProfile = self.attributes[.provisioning_profile] as? String
        let exportEntitlements = ExportEntitlements(name: targetName,
              entitlements: entitlements,
              provisioningProfile: provisioningProfile,
              bundleID: bundleID)
        return exportEntitlements
    }

    func extractCodeSignEntitlementsFile(genOptions: XCHammerGenerateOptions) -> String? {
        guard needsRecursiveExtraction,
              bundleID != nil else {
            return nil
        }

        let label = BuildLabel(self.label.value + "_entitlements")
        guard targetMap.anyXcodeTarget(withBuildLabel: label) != nil else {
            return nil
        }

        // The above rules ( written to the code gen'd build file )
        // dumps entitlements to this file
        let relativeProjDir = genOptions.outputProjectPath.string
                .replacingOccurrences(of: genOptions.workspaceRootPath.string,
                                    with: "")
        let targetName = label.asFullPBXTargetName!
        return XCHammerIncludesSRCRoot + relativeProjDir + "/XCHammerAssets/" + targetName + ".entitlements"
    }

    var mobileProvisionProfileFile: String? {
        return ruleEntry.normalNonSourceArtifacts
            .first { $0.subPath.hasSuffix("mobileprovision") }
            .map(getXCSourceRootAbsolutePath(for:))
    }

    var isEntitlementsDep: Bool {
        return label.value.hasSuffix("entitlements")
    }

    func extractDefines(map targetMap: XcodeTargetMap) -> [String] {
        // Get the defines on the current rule and any defines on it's child rules
        let allDefines = ([self] + transitiveTargets(map: targetMap, predicate: stopAfterNeedsRecursive))
            .flatMap { $0.defines ?? [] }
        // dedupe
        return Array(Set(allDefines))
    }

    lazy var xcBundles: [ProjectSpec.TargetSource] = {
        let bundleResources = ([self] + self.transitiveTargets(map:
                    self.targetMap,
                    predicate: stopAfterNeedsRecursive))
            .filter { isBundle($0.type) }
            .flatMap { $0.xcResources }
        return Set(bundleResources.map { self.resolveExternalPath(for: $0.path) }).map { ProjectSpec.TargetSource(path: $0) }
    }()

    func extractLibraryDeps(map targetMap: XcodeTargetMap) -> [String] {
        return transitiveTargets(map: targetMap, predicate: stopAfterNeedsRecursive)
            .filter { $0.type == "objc_import" }
            .compactMap { target -> [String]? in
                guard let archives = target.attributes[.archives] as? [[String: Any]] else {
                    return nil
                }
                return archives.map { $0["path"] as! String }
            }.flatMap { $0 }.sorted()
    }


    func extractAttributeArray(attr: RuleEntry.Attribute, map targetMap: XcodeTargetMap) -> [String] {
        if needsRecursiveExtraction {
            return ([self] + transitiveTargets(map: targetMap, predicate: stopAfterNeedsRecursive))
                .flatMap { $0.attributes[attr] as? [String] ?? [] }
        } else {
            return attributes[attr] as? [String] ?? []
        }
    }

    lazy var SDKFrameworks: [String] = {
        return self.extractAttributeArray(attr: .sdk_frameworks, map: self.targetMap)
            .sorted()
    }()

    lazy var SDKDylibs: [String] = {
        return self.extractAttributeArray(attr: .sdk_dylibs, map: self.targetMap)
            .map { $0.hasPrefix("lib") ? String($0.dropFirst(3)) : $0 }
            .sorted()
    }()

    lazy var weakSDKFrameworks: [String] = {
        return self.extractAttributeArray(attr: .weak_sdk_frameworks, map: self.targetMap)
            .sorted()
    }()

    fileprivate var xcExtensionDeps: [ProjectSpec.Dependency] {
        // Assume extensions are contained in the same workspace
        return extensions
            .compactMap {
                label -> XcodeTarget? in
                guard let target = targetMap.xcodeTarget(buildLabel: label,
                        depender: self) else {
                    return nil
                }
                guard targetMap.includedProjectTargets.contains(target) else {
                    return nil
                }
                return target
            }.map {
                xcodeTarget in
                var mutableDep = ProjectSpec.Dependency(type: .target,
                        reference: xcodeTarget.xcTargetName, embed: xcodeTarget.isExtension)
                mutableDep.codeSign = false
                return mutableDep
            }
    }

    func extractModuleMap() -> String? {
        return (self.sourceFiles + self.nonARCSourceFiles)
            .first(where: { $0.subPath.hasSuffix(".modulemap") })
            .map(getXCSourceRootAbsolutePath)
    }

    func extractHeaderMap() -> String? {
        return (self.sourceFiles + self.nonARCSourceFiles)
            .first(where: { $0.subPath.hasSuffix(".hmap") })
            .map {
                return subBazelMakeVariables(getRelativePath(for: $0),
                    useSRCRoot: false)
             }
    }

    func extractProductType() -> ProductType? {
        let BuildTypeToTargetType = [
            "apple_ui_test": ProductType.UIUnitTest, // TODO: Remove deprecated rule
            "ios_ui_test": ProductType.UIUnitTest,
            "apple_unit_test": ProductType.UnitTest, // TODO: Remove deprecated rule
            "ios_unit_test": ProductType.UnitTest,
            "cc_binary": ProductType.Application,
            "cc_library": ProductType.StaticLibrary,
            "ios_application": ProductType.Application,
            "ios_extension": ProductType.AppExtension,
            "ios_framework": ProductType.Framework,
            "apple_framework_packaging": ProductType.Framework,
            "ios_test": ProductType.UnitTest,
            "macos_application": ProductType.Application,
            "macos_command_line_application": ProductType.Tool,
            "macos_extension": ProductType.AppExtension,
            "objc_binary": ProductType.Application,
            //"objc_library": ProductType.StaticLibrary,
            "objc_bundle_library": ProductType.Bundle, // TODO: Remove deprecated rule
            "apple_resource_bundle": ProductType.Bundle,
            "objc_framework": ProductType.Framework,
            "apple_static_framework_import": ProductType.Framework,
            //"swift_library": ProductType.StaticLibrary,
            "swift_c_module": ProductType.StaticLibrary,
            "tvos_application": ProductType.Application,
            "tvos_extension": ProductType.TVAppExtension,
            "watchos_application": ProductType.Watch2App,
            "watchos_extension": ProductType.Watch2Extension,
            "ios_imessage_extension": ProductType.IMessageExtension,
            // A Tulsi-internal generic "test host", used to generate build targets that act as hosts for
            // XCTest test rules.
            "_test_host_": ProductType.Application,
        ]

        guard let productType = BuildTypeToTargetType[self.type] else {
            return nil
        }
        return productType
    }

    /// Get a Bazel build target
    /// This uses a custom build_bazel.py which requires:
    /// - LLDB init style debug setup for speed and cachability
    /// - Custom debug mapping in clang frontend via Bazel tweaks
    /// It is not enabled by default due to the above implications.
    func getBazelBuildableTarget() -> ProjectSpec.Target? {
        guard let productType = extractProductType() else {
            return nil
        }

        let platform = { (xcodeTarget: XcodeTarget) -> String in
            if let deploymentTarget = xcodeTarget.deploymentTarget {
                switch deploymentTarget.platform {
                case .ios: return "iOS"
                case .macos: return "macOS"
                case .tvos: return "tvOS"
                case .watchos: return "watchOS"
                }
            } else {
                return "iOS"
            }
        }(self)

        let targetConfig = XcodeTarget.getTargetConfig(for: self)
        let bazelBase: String
        if let xchammerPath = genOptions.xcodeProjectRuleInfo?.xchammerPath {
            bazelBase = xchammerPath + "/Contents/Resources"
        } else {
            bazelBase = Bundle.main.resourcePath!
        }

        let buildInvocation = "\(bazelBase)/bazel_build.py \(label.value) --bazel \(genOptions.bazelPath.string)"


        let getScriptContent: (() -> String) = {
            guard
                let templatePath = targetConfig?.buildBazelTemplate,
                let template = try? String(contentsOf: (self.genOptions.workspaceRootPath + Path(
                    templatePath)).url) else {
                return """
                \(buildInvocation)
                """
            }
            return template.replacingOccurrences(of: "__BAZEL_COMMAND__",
                    with:
                """
                \(buildInvocation)
                """)
        }

        // Minimal settings for this build
        var settings = XCBuildSettings()

        /// We need to include the sources into the target
        let sources: [ProjectSpec.TargetSource]
        let xcodeBuildableTargetSettings: XCBuildSettings
        if shouldFuseDirectDeps {
            let flattened = Set(flattenedInner(targetMap: targetMap))
            // Determine deps to fuse into the rule.
            let pathsPredicate = makePathFiltersPredicate(genOptions.pathsSet)
            let fusableDeps = self.unfilteredDependencies
                .filter { flattened.contains($0) && includeTarget($0, pathPredicate:
                        pathsPredicate) }
            //print("FusbableDeps", fusableDeps.map { $0.label })
            xcodeBuildableTargetSettings = self.settings
                            <> fusableDeps.foldMap { $0.settings }
            // Use settings, sources, and deps from the fusable deps
            sources = fusableDeps.flatMap { $0.xcCompileableSources }
            // Notes on test host build configuration:
            // - Xcode bazel-builds the app as a scheme dep
            // - Xcode bazel-builds the test which install the test bundle into the
            //   app
            settings.testHost = xcodeBuildableTargetSettings.testHost
            settings.testTargetName = xcodeBuildableTargetSettings.testTargetName

            // This is required to codesign the Runner.app with the right
            // entitlement.
            // TODO: support custom entitlements for on device.
            if settings.testTargetName != nil {
                settings.codeSigningAllowed = First("YES")
            }
        } else {
            sources = self.xcCompileableSources
            xcodeBuildableTargetSettings = self.settings
            settings.infoPlistFile = xcodeBuildableTargetSettings.infoPlistFile
        }

        settings.cc = First("$(PROJECT_FILE_PATH)/XCHammerAssets/xcode_clang_stub.sh")
        settings.ld = First("$(PROJECT_FILE_PATH)/XCHammerAssets/xcode_ld_stub.sh")
        settings.swiftc = First("$(PROJECT_FILE_PATH)/XCHammerAssets/swiftc_stub.py")

        settings.debugInformationFormat = First("dwarf")
        settings.headerSearchPaths = xcodeBuildableTargetSettings.headerSearchPaths
        settings.copts = xcodeBuildableTargetSettings.copts
        settings.swiftCopts = xcodeBuildableTargetSettings.swiftCopts

        settings.isBazel = First("YES")
        settings.onlyActiveArch = First("YES")
        settings.codeSigningRequired = First("NO")
        settings.codeSigningAllowed = First("NO")
        settings.productName <>= First("$(TARGET_NAME)")
        // A custom XCHammerAsset bazel_build_settings.py is loaded by bazel_build.py
        settings.pythonPath =
            First("${PYTHONPATH}:$(PROJECT_FILE_PATH)/XCHammerAssets")
        settings <>= getDeploymentTargetSettings()

        let bazelScript = ProjectSpec.BuildScript(path: nil, script: getScriptContent(),
                name: "Bazel build")
        return ProjectSpec.Target(
            name: xcTargetName,
            type: PBXProductType(rawValue: productType.rawValue)!,
            platform: Platform(rawValue: platform)!,
            settings: makeXcodeGenSettings(from: settings),
            configFiles: getXCConfigFiles(for: self),
            sources: sources,
            dependencies: [],
            postBuildScripts: [bazelScript]
        )
    }

    public func getXcodeBuildableTarget() -> ProjectSpec.Target? {
        let xcodeTarget = self
        let genOptions = xcodeTarget.genOptions
        let config = genOptions.config
        let targetMap = xcodeTarget.targetMap
        guard let type = xcodeTarget.xcType,
              let productType = xcodeTarget.extractProductType() else {
            return nil
        }
        //TODO: (jerry) move this into `includedTargets`
        let flattened = Set(flattenedInner(targetMap: targetMap))
        /*
        guard flattened.contains(xcodeTarget) == false, xcodeTarget.type == "apple_framework_packaging" else {
            return nil
        }*/

        let pathsPredicate = makePathFiltersPredicate(genOptions.pathsSet)
        guard includeTarget(xcodeTarget, pathPredicate: pathsPredicate) == true
    else {
                return nil
            }

        let xcodeTargetSources = xcodeTarget.xcSources
        let sources: [ProjectSpec.TargetSource]
        let settings: XCBuildSettings
        let deps: [ProjectSpec.Dependency]
        // Find the linked deps and extract the deps name
        // We need actual targets here, since these are things like Applications
        let linkedDeps = xcodeTarget.linkedTargetLabels
            .compactMap { targetMap.xcodeTarget(buildLabel: $0, depender: xcodeTarget) }
            .filter { includeTarget($0, pathPredicate: pathsPredicate) }
            .map { ProjectSpec.Dependency(type: .target, reference: $0.xcTargetName,
                    embed: $0.isExtension) }

        // Determine settings, sources, and deps
        // There are 2 different possibilities:
        // 1) High level "Fusing" of a target from multiple targets
        // 2) A simple conversion of the target: taking it "as is"
        if shouldFlatten(xcodeTarget: xcodeTarget) {
            /*
            print("UFD", xcodeTarget.label, xcodeTarget.unfilteredDependencies
                  .filter { flattened.contains($0) }
                  .map { $0.label.value }.debugDescription)
            */
            // Determine deps to fuse into the rule.
            let fusableDeps = xcodeTarget.unfilteredDependencies
                .filter { flattened.contains($0) && includeTarget($0, pathPredicate:
                        pathsPredicate) }

            //print("FD", xcodeTarget.label, fusableDeps.map { $0.label.value }.debugDescription)
            // Use settings, sources, and deps from the fusable deps
            sources = fusableDeps.flatMap { $0.xcSources }
            settings = xcodeTarget.settings
                <> fusableDeps.foldMap { $0.settings }
            if shouldPropagateDeps(forTarget: xcodeTarget) {
                deps = fusableDeps
                    .flatMap { $0.xcLinkableTransitiveDeps } + xcodeTarget.xcExtensionDeps
            } else {
                deps = []
            }
        } else {
            sources = xcodeTargetSources
            settings = xcodeTarget.settings
            if shouldPropagateDeps(forTarget: xcodeTarget) {
                deps = Array(xcodeTarget.xcLinkableTransitiveDeps) +
                    xcodeTarget.xcExtensionDeps
            } else {
                deps = []
            }
        }

        func getComposedSettings() -> XCBuildSettings {
            guard let codeSignEntitlementsFile =
                xcodeTarget.extractCodeSignEntitlementsFile(genOptions: genOptions) else {
                return settings
            }

            // Compose entitlements linker flags on, if they are detected by hacky assumptions
            let simEntitlementsLDFlags: OrderedArray<String> = OrderedArray(["-sectcreate __TEXT __entitlements \(codeSignEntitlementsFile)"])
            var eSettings = XCBuildSettings()
            eSettings.ldFlags = Setting(base: nil, SDKiPhoneSimulator: simEntitlementsLDFlags, SDKiPhone: nil)

            if let mobileProvisionProfileFile = xcodeTarget.mobileProvisionProfileFile {
                eSettings.mobileProvisionProfileFile = First(mobileProvisionProfileFile)
                eSettings.codeSignEntitlementsFile = First(codeSignEntitlementsFile)
            }
            return settings <> eSettings
        }

        let (prebuildScripts, postbuildScripts) = makeScripts(for: xcodeTarget, genOptions: genOptions, targetMap: targetMap)
        let platform = { (xcodeTarget: XcodeTarget) -> String in
            if let deploymentTarget = xcodeTarget.deploymentTarget {
                switch deploymentTarget.platform {
                case .ios: return "iOS"
                case .macos: return "macOS"
                case .tvos: return "tvOS"
                case .watchos: return "watchOS"
                }
            } else {
                return "iOS"
            }
        }(xcodeTarget)

       // print("LD", linkedDeps, "D", deps)
        let d = Array(Set(deps))
            .sorted(by:{ $0.reference  < $1.reference })

        return ProjectSpec.Target(
            name: xcodeTarget.xcTargetName,
            type: PBXProductType(rawValue: productType.rawValue)!,
            platform: Platform(rawValue: platform)!,
            settings: makeXcodeGenSettings(from: getComposedSettings()),
            configFiles: getXCConfigFiles(for: xcodeTarget),
            sources: sources,
            dependencies:  d,
            //dependencies:  
            //Array(Set(deps + linkedDeps))
            //     .sorted(by:{ $0.reference  < $1.reference }),
            preBuildScripts: prebuildScripts,
            postBuildScripts: postbuildScripts
        )
    }


    public func getLaunchAutomaticallySubstyle() -> String? {
        // Support for launch substyle.
        switch extensionType {
        // Some extension types require a remote debuggable and different
        // runtime configuration. Simply put, at launch, this auto selects
        // the executable. This closely mirrors how Xcode sets up the schemes
        case "com.apple.intents-service", "com.apple.message-payload-provider":
            return "2"
        default:
            // Use the default value for this, which ends up being "0"
            return nil
        }
    }
}

// MARK: - Equatable

public func ==(lhs: XcodeTarget, rhs: XcodeTarget) -> Bool {
    return lhs.equals(rhs)
}

/// Return true when flatten flat
func shouldFlatten(xcodeTarget: XcodeTarget) -> Bool {
    return xcodeTarget.shouldFuseDirectDeps
}

/// Mark - XcodeGen support

private func makeScripts(for xcodeTarget: XcodeTarget, genOptions: XCHammerGenerateOptions, targetMap: XcodeTargetMap) -> ([ProjectSpec.BuildScript], [ProjectSpec.BuildScript]) {
    func getProcessScript() -> ProjectSpec.BuildScript {
        // Use whatever XCHammer this project was built with
        let xchammerBin = Generator.getXCHammerBinPath(genOptions: genOptions)
        let processContent = "\(xchammerBin) process_ipa"
        return  ProjectSpec.BuildScript(path: nil, script: processContent, name: "Process IPA")
    }

    func getCodeSignerScript() -> ProjectSpec.BuildScript {
        let codeSignerContent = "$PROJECT_FILE_PATH/" + XCHammerAsset.codesigner.getPath()
        return ProjectSpec.BuildScript(path: nil, script: codeSignerContent, name: "Codesign")
    }

    let basePostScripts: [ProjectSpec.BuildScript]
    let basePreScripts: [ProjectSpec.BuildScript] = []
    if xcodeTarget.needsRecursiveExtraction,
        xcodeTarget.mobileProvisionProfileFile != nil,
        xcodeTarget.extractCodeSignEntitlementsFile(genOptions: genOptions) != nil {
        basePostScripts = xcodeTarget.type.contains("application") ||
        xcodeTarget.type == "apple_ui_test" ||
        xcodeTarget.type == "ios_ui_test"
            ? [getProcessScript(), getCodeSignerScript()] : [getCodeSignerScript()]
    } else {
        basePostScripts = xcodeTarget.type.contains("application") ? [getProcessScript()] : []
    }

    return (basePreScripts, basePostScripts)
}


