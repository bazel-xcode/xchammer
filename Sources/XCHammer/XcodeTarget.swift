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

private func shouldPropagateDeps(forTarget xcodeTarget: XcodeTarget) -> Bool {
    return xcodeTarget.needsRecursiveExtraction && xcodeTarget.label.packageName?.hasPrefix("@") == false
}

/// Return XCConfig files
/// Currently we support `Diags.xcconfig`, the base for all
/// warning flags.
private func getDiagsXCConfigFiles(for target: XcodeTarget, genOptions: XCHammerGenerateOptions) -> [String: String] {
    // Linear search a sequence of Maybe XCConfigs for the first XCConfig
    // Bias towards a Diags.xcconfig closest to the BUILD file
    let components = target.buildFilePath!.components(separatedBy: "/")
    let maybeXCConfig = components
        .lazy
        .enumerated()
        .reversed()
        .map {
            idx, _ -> String in
           let ext = (idx == 0 ? "" : "/") + "Diags.xcconfig"
           return components[0..<idx].joined(separator: "/") + ext
        }.first { (genOptions.workspaceRootPath + Path($0)).isFile }
    if let xcconfig = maybeXCConfig {
        return ["Debug": xcconfig, "Release": xcconfig]
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



func includeTarget(_ xcodeTarget: XcodeTarget, pathPredicate: (String) -> Bool) -> Bool {
    guard let buildFilePath = xcodeTarget.buildFilePath else {
        return false
    }
    guard pathPredicate(buildFilePath) else {
        return false
    }
    if xcodeTarget.frameworkImports.count > 0 {
        return false
    }
    if shouldPropagateDeps(forTarget: xcodeTarget) {
        return true
    }

    if xcodeTarget.type == "objc_bundle_library" {
        return true
    }

    // Skip targets without implementations
    let impls = (xcodeTarget.sourceFiles + xcodeTarget.nonARCSourceFiles)
        .map { $0.subPath }
        .filter { !$0.hasSuffix(".modulemap") && !$0.hasSuffix(".hmap") && !$0.hasSuffix(".h") }
    if impls.count == 0 {
        return false
    }

    guard let _ = xcodeTarget.xcType,
        xcodeTarget.label.packageName!.hasPrefix("@") == false else {
        return false
    }
    return true
}

// Traversal predicates
private let stopAfterNeedsRecursive: TraversalTransitionPredicate<XcodeTarget> = TraversalTransitionPredicate { $0.needsRecursiveExtraction ? .justOnceMore : .keepGoing }
private let stopAtBundles: TraversalTransitionPredicate<XcodeTarget> = TraversalTransitionPredicate { $0.type == "objc_bundle_library" ? .stop : .keepGoing }

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
            "apple_ui_test"
        ]
        let value = self.isTopLevelTestTarget || (
            type.map { needsRecursiveTypes.contains($0) } ?? false
        )
        return value
    }()

    lazy var xcTargetName: String = {
        let numberOfEntries = self.targetMap.targets(buildLabel: self.label).count
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
            return "$(SRCROOT)/" + fileInfo.subPath
        case .generatedFile:
            return "$(SRCROOT)/bazel-genfiles/" + fileInfo.subPath
        }
    }

    func getRelativePath(for fileInfo: BazelFileInfo) -> String {
        switch fileInfo.targetType {
        case .sourceFile:
            return fileInfo.subPath
        case .generatedFile:
            return "bazel-genfiles/" + fileInfo.subPath
        }
    }

    lazy var unfilteredDependencies: [XcodeTarget] = {
        let unwrapSuffixes: Set<String> = [
            ".apple_binary",
            "_test_bundle",
            "_test_binary",
        ]

        return self.dependencies
            .compactMap { self.targetMap.xcodeTarget(buildLabel: $0, depender: self) }
            .flatMap { xcodeTarget in
                (unwrapSuffixes.map { xcodeTarget.label.value.hasSuffix($0) }.any()) ?
                    xcodeTarget.unfilteredDependencies :
                    [xcodeTarget]
            }
    }()

    lazy var xcSources: [ProjectSpec.TargetSource] = {
        let sourceFilePaths = self.sourceFiles
            .map { sourceInfo -> String in
                return self.getRelativePath(for: sourceInfo)
            }
        
        let sourceFiles = sourceFilePaths
            .filter { !$0.hasSuffix(".modulemap") && !$0.hasSuffix(".hmap") }
            .map { ProjectSpec.TargetSource(path: $0) }

        let nonArcFiles = self.nonARCSourceFiles
            .map { ProjectSpec.TargetSource(path: $0.subPath, compilerFlags: ["-fno-objc-arc"]) }
        let resources = self.xcResources
        let bundles = self.xcBundles

        let all: [ProjectSpec.TargetSource] = resources + nonArcFiles + (sourceFiles.filter { !$0.path.hasSuffix("h") }.count > 0 ?
            sourceFiles :
            [ProjectSpec.TargetSource(path: XCHammerAsset.stubImp.getPath(underProj:
                    self.genOptions.outputProjectPath), compilerFlags: ["-x objective-c", "-std=gnu99"])]
        ) + bundles
        let s: Set<ProjectSpec.TargetSource> = Set(all)
        return Array(s)
    }()

    func transitiveTargets(map targetMap: XcodeTargetMap, predicate:
            TraversalTransitionPredicate<XcodeTarget> =
            TraversalTransitionPredicate<XcodeTarget>.empty, force: Bool = true) -> [XcodeTarget] {
        if !force && !needsRecursiveExtraction {
            return []
        }

        return unfilteredDependencies.flatMap { (xcodeTarget: XcodeTarget) -> [XcodeTarget] in
            switch predicate.run(xcodeTarget) {
            case .stop:
                return []
            case .justOnceMore:
                return [xcodeTarget]
            case .keepGoing:
                return [xcodeTarget] + xcodeTarget.transitiveTargets(map: targetMap,
                        predicate: predicate, force: force)
            }
        }
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

    func pathsForAttrs(attrs: Set<RuleEntry.Attribute>) -> [Path] {
        return attrs.flatMap { attr in
            self.attributes[attr] as? [[String: Any]] ??
                (self.attributes[attr] as? [String: Any]).map{ [$0] } ??
                []
            }.compactMap { $0["path"] as? String }.map { Path($0) }
    }

    func isAllowableXcodeGenSource(path: Path) -> Bool {
        // These files are handled in other ways.
        return path.extension != "mobileprovision"
    }

    lazy var myResources: [ProjectSpec.TargetSource] = {
        let resources: [ProjectSpec.TargetSource] = self.pathsForAttrs(attrs: [.launch_storyboard, .supporting_files])
            .filter(self.isAllowableXcodeGenSource(path:))
            .compactMap { path in
            let pathComponents = path.components
            if let specialIndex = (pathComponents.index { component in
                DirectoriesAsFileSuffixes.map { component.hasSuffix("." + $0) }.any()
            }) {
                let formattedPath = Path(pathComponents[pathComponents.startIndex ... specialIndex].joined(separator: Path.separator))
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

        let structuredResources: [ProjectSpec.TargetSource] = self.pathsForAttrs(attrs: [.structured_resources]).compactMap { resourcePath -> ProjectSpec.TargetSource? in
            guard let buildFilePath = self.buildFilePath else { return nil }
            let basePath = Path(buildFilePath).parent().normalize()
            // now we can recover the relative path provided inside the build files
            let buildFileRelativePath = Path(resourcePath.string.replacingOccurrences(of: basePath.string + "/", with: ""))
            // the structured path is the first directory relative to the build file dir
            let structuredPath = basePath + Path(buildFileRelativePath.components[0])
            // structured resources are rendered as folder-references in Xcode
            return ProjectSpec.TargetSource(path: structuredPath.string, compilerFlags:
                    [], type: .folder)
        }

        // Normalize for Xcode
        // - dedupe
        // - frameworks shouldn't be injested as a resource or a source
        return Array(Set(resources + structuredResources))
                .filter { !$0.path.hasSuffix(".framework") }
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
            case .AppExtension, .XPCService, .Watch1App, .Watch2App, .Watch1Extension, .Watch2Extension, .TVAppExtension:
            return xcTargetName + ".appex"
            default:
            fatalError()
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
    lazy var transitiveDeps: Set<ProjectSpec.Dependency> = {
        let deps = self.transitiveTargets(map: self.targetMap, predicate:
                stopAfterNeedsRecursive, force: true)
            .flatMap { xcodeTarget -> [ProjectSpec.Dependency] in
                guard let linkableProductName =
                    xcodeTarget.extractLinkableBuiltProductName(map:
                            self.targetMap), includeTarget(xcodeTarget, pathPredicate:
                        alwaysIncludePathPredicate) else {
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

                // make an explicit dep if it's valid
                return [ProjectSpec.Dependency(type: .framework, reference: linkableProductName,
                        embed: xcodeTarget.isExtension)]
                    + xcodeTarget.xcDependencies
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

        var settings = XCBuildSettings()
        self.attributes.forEach { attr, value in
            switch attr {
                // TODO: Implement the rest of the attributes enum
            case .copts:
                if let coptsArray = value as? [String] {
                    let processedOpts = coptsArray.map { opt -> String in
                        if opt.hasPrefix("-I") {
                            let substringRangeStart = opt.index(opt.startIndex, offsetBy: 2)
                            let path = opt[substringRangeStart...]
                            let processedOpt =  "-I$(SRCROOT)/\(path)"
                            return processedOpt
                        } else {
                            return opt
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
                if self.type == "apple_ui_test" {
                    // USES_XCTRUNNER is set by Xcode automatically so we just need to set the test target name
                    settings.testTargetName <>= First(xcTargetName)
                } else {
                    settings.testHost <>= First("$(BUILT_PRODUCTS_DIR)/\(xcTargetName).app/\(xcTargetName)")
                    settings.bundleLoader <>= First("$(TEST_HOST)")
                }
            case .test_bundle:
                // These are actual ProjectSpec.Targets'
                break
            case .sdk_dylibs, .sdk_frameworks, .weak_sdk_frameworks:
                // These are implemented below
                break
            case .launch_storyboard, .structured_resources, .entitlements, .provisioning_profile:
                break // These attrs are not related to XCConfigs
            case .binary:
                break // Explicitly not handled since it is a implicit target we don't intend to handle
            default:
                print("TODO: Unimplemented attribute \(attr) \(value)")
            }
        }

        // Product Name
        settings.productName <>= self.bundleName.map { First($0) }

        // Product Bundle Identifier
        settings.productBundleId <>= self.bundleID.map { First($0) }

        // Set Header Search Paths
        if let headerSearchPaths = self.includePaths {
            settings.headerSearchPaths <>= OrderedArray(["$(inherited)"]) <> headerSearchPaths
                .filter { !$0.0.contains("tulsi-includes") }
                .foldMap { (path: String, isRecursive: Bool) in
                if path.hasSuffix("module_map") {
                    return ["$(SRCROOT)/bazel-genfiles/\(path)"]
                } else if isRecursive {
                    return ["$(SRCROOT)/\(path)/**"]
                } else {
                    return ["$(SRCROOT)/\(path)"]
                }
            }
        }

        // Add my own + transitive header maps to copts
        settings.copts <>= ([self] + self.transitiveTargets(map: targetMap))
            .compactMap { $0.self.extractHeaderMap() }
            .map { "-iquote \($0)" }

        // Delegate warnings and error config to xcconfig for targets that have
        // a diagnostics xcconfig.
        let configs = getDiagsXCConfigFiles(for: self, genOptions: genOptions)
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

        // Set thes deployment target if available
        if let deploymentTgt = self.deploymentTarget {
            switch deploymentTgt.platform {
            case .ios: settings.iOSDeploymentTarget <>= First(deploymentTgt.osVersion)
            case .tvos: settings.tvOSDeploymentTarget <>= First(deploymentTgt.osVersion)
            case .watchos: settings.watchOSDeploymentTarget <>= First(deploymentTgt.osVersion)
            case .macos: settings.macOSDeploymentTarget <>= First(deploymentTgt.osVersion)
            }
        }

        // Add defines as copts
        settings.copts <>= processDefines(defines: self.extractDefines(map: targetMap))

        if let moduleMapPath = self.extractModuleMap() {
            settings.moduleMapFile <>= First(moduleMapPath)
            settings.enableModules <>= First("YES")
        }

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
    }

    lazy var isTopLevelTestTarget: Bool = {
        return self.xcType?.contains("-test") ?? false
    }()

    lazy var xcDependencies: [ProjectSpec.Dependency] = {
        guard self.frameworkImports.count > 0 else {
            return []
        }

        // TODO: Move this to transitiveDeps
        let xcodeTargetDeps: [XcodeTarget] = self.dependencies.compactMap {
            depLabel in
            let depName = depLabel.value
            guard let target = self.targetMap.xcodeTarget(buildLabel: depLabel, depender: self) else {
                return nil
            }

            guard target.frameworkImports.count == 0 else {
                return nil
            }

            if depName.hasSuffix(".apple_binary") {
                let unwrappedDeps = target.dependencies
                for depEntry in unwrappedDeps {
                    // If it's an iOS app, strip out entitlements
                    if depEntry.value.hasSuffix("entitlements") {
                        continue
                    }

                    if let foundTarget = self.targetMap.xcodeTarget(buildLabel:
                            depEntry, depender: self) {
                        return foundTarget
                    }
                }
            }
            return target
        }

        return xcodeTargetDeps
            .filter { includeTarget($0, pathPredicate: alwaysIncludePathPredicate) }
            .compactMap { ProjectSpec.Dependency(type: .target, reference: $0.xcTargetName,
                    embed:
                    $0.isExtension) } + self.frameworkDependencies
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
        return "$(SRCROOT)/bazel-genfiles" + relativeProjDir + "/XCHammerAssets/" + targetName + ".entitlements"
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
            .filter { $0.type == "objc_bundle" }
            .flatMap { $0.xcResources }
        return Set(bundleResources.map { $0.path }).map { ProjectSpec.TargetSource(path: $0) }
    }()

    func extractLibraryDeps(map targetMap: XcodeTargetMap) -> [String] {
        return transitiveTargets(map: targetMap, predicate: stopAfterNeedsRecursive)
            .filter { $0.type == "objc_import" }
            .compactMap { target -> [String]? in
                guard let archives = target.attributes[.archives] as? [[String: Any]] else {
                    return nil
                }
                return archives.map { $0["path"] as! String }
            }.flatMap { $0 }
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
    }()

    lazy var SDKDylibs: [String] = {
        return self.extractAttributeArray(attr: .sdk_dylibs, map: self.targetMap)
            .map { $0.hasPrefix("lib") ? String($0.dropFirst(3)) : $0 }
    }()

    lazy var weakSDKFrameworks: [String] = {
        return self.extractAttributeArray(attr: .weak_sdk_frameworks, map: self.targetMap)
    }()

    fileprivate var xcExtensionDeps: [ProjectSpec.Dependency] {
        // Assume extensions are contained in the same workspace
        return extensions
            .compactMap { targetMap.xcodeTarget(buildLabel: $0, depender: self) }
            .map { 
                var mutableDep = ProjectSpec.Dependency(type: .target, reference: $0.xcTargetName,
                                               embed: $0.isExtension)
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
                return getXCSourceRootAbsolutePath(for: $0)
                    // __BAZEL_GEN_DIR__ is a custom toolchain make variable
                    // resolve that to $(SRCROOT)/bazel-genfiles.
                    .replacingOccurrences(of: "__BAZEL_GEN_DIR__", with: "")
             }
    }

    func extractProductType() -> ProductType? {
        let BuildTypeToTargetType = [
            "apple_ui_test": ProductType.UIUnitTest,
            "apple_unit_test": ProductType.UnitTest,
            "cc_binary": ProductType.Application,
            "cc_library": ProductType.StaticLibrary,
            "ios_application": ProductType.Application,
            "ios_extension": ProductType.AppExtension,
            "ios_framework": ProductType.Framework,
            "ios_test": ProductType.UnitTest,
            "macos_application": ProductType.Application,
            "macos_command_line_application": ProductType.Tool,
            "macos_extension": ProductType.AppExtension,
            "objc_binary": ProductType.Application,
            "objc_library": ProductType.StaticLibrary,
            "objc_bundle_library": ProductType.Bundle,
            "objc_framework": ProductType.Framework,
            "swift_library": ProductType.StaticLibrary,
            "tvos_application": ProductType.Application,
            "tvos_extension": ProductType.TVAppExtension,
            "watchos_application": ProductType.Watch2App,
            "watchos_extension": ProductType.Watch2Extension,
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

        // TODO: Support testing in Bazel
        guard isTopLevelTestTarget == false else {
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

        let targetConfig = genOptions.config.getTargetConfig(for: label.value)

        // bazel_build.py is adjacent to the XCHammer bin
        let buildInvocation = dirname(ProcessInfo.processInfo.arguments[0]) +
            "/bazel_build.py " + label.value + " --bazel " +
            genOptions.bazelPath.string

        let getScriptContent: (() -> String) = {
            guard
                let templatePath = targetConfig?.buildBazelTemplate,
                let template = try? String(contentsOf: (self.genOptions.workspaceRootPath + Path(
                    templatePath)).url) else {
                return """
                export TULSI_USE_HAMMER_DEBUG_CONFIG=YES
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
        settings.codeSigningRequired <>= First("NO")

        // A custom XCHammerAsset bazel_build_settings.py is loaded by bazel_build.py
        settings.pythonPath =
            First("${PYTHONPATH}:$(PROJECT_FILE_PATH)/XCHammerAssets")

        let bazelScript = ProjectSpec.BuildScript(path: nil, script: getScriptContent(),
                name: "Bazel build")
        return ProjectSpec.Target(
            name: xcTargetName + "-Bazel",
            type: PBXProductType(rawValue: productType.rawValue)!,
            platform: Platform(rawValue: platform)!,
            settings: makeXcodeGenSettings(from: settings),
            configFiles: [String: String](),
            sources: [],
            dependencies: [],
            prebuildScripts: [bazelScript],
            scheme: nil,
            legacy: nil
        )
    }
}

// MARK: - Equatable

public func ==(lhs: XcodeTarget, rhs: XcodeTarget) -> Bool {
    return lhs.equals(rhs)
}

/// Return true when flatten flat
func shouldFlatten(xcodeTarget: XcodeTarget) -> Bool {
    return xcodeTarget.isTopLevelTestTarget
}

/// Mark - XcodeGen support

private func makeScripts(for xcodeTarget: XcodeTarget, genOptions: XCHammerGenerateOptions, targetMap: XcodeTargetMap) -> ([ProjectSpec.BuildScript], [ProjectSpec.BuildScript]) {
    func getProcessScript() -> ProjectSpec.BuildScript {
        // Use whatever XCHammer this project was built with
        let processContent = "\(CommandLine.arguments[0]) process-ipa"
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
        basePostScripts = xcodeTarget.type.contains("application") ? [getProcessScript(), getCodeSignerScript()] : [getCodeSignerScript()]
    } else {
        basePostScripts = xcodeTarget.type.contains("application") ? [getProcessScript()] : []
    }

    return (basePreScripts, basePostScripts)
}

public func makeXcodeGenTarget(from xcodeTarget: XcodeTarget) -> ProjectSpec.Target? {
    let genOptions = xcodeTarget.genOptions
    let config = genOptions.config
    let targetMap = xcodeTarget.targetMap
    guard let type = xcodeTarget.xcType,
          let productType = xcodeTarget.extractProductType() else {
        return nil
    }
    //TODO: (jerry) move this into `includedTargets`
    let flattened = Set(flattenedInner(targetMap: targetMap))
    guard flattened.contains(xcodeTarget) == false else {
        return nil
    }

    let xcodeTargetSources = xcodeTarget.xcSources
    let sources: [ProjectSpec.TargetSource]
    let settings: XCBuildSettings
    let deps: [ProjectSpec.Dependency]
    let pathsPredicate = makePathFiltersPredicate(genOptions.pathsSet)
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
        // Determine deps to fuse into the rule.
        let fusableDeps = xcodeTarget.unfilteredDependencies
            .filter { flattened.contains($0) && includeTarget($0, pathPredicate:
                    pathsPredicate) }

        // Use settings, sources, and deps from the fusable deps
        sources = fusableDeps.flatMap { $0.xcSources }
        settings = xcodeTarget.settings
            <> fusableDeps.foldMap { $0.settings }
        if shouldPropagateDeps(forTarget: xcodeTarget) {
            deps = fusableDeps
                .flatMap { $0.transitiveDeps } + xcodeTarget.xcExtensionDeps
        } else {
            deps = []
        }
    } else {
        sources = xcodeTargetSources
        settings = xcodeTarget.settings

        if shouldPropagateDeps(forTarget: xcodeTarget) {
            deps = Array(xcodeTarget.transitiveDeps) +
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
    
    return ProjectSpec.Target(
        name: xcodeTarget.xcTargetName,
        type: PBXProductType(rawValue: productType.rawValue)!,
        platform: Platform(rawValue: platform)!,
        settings: makeXcodeGenSettings(from: getComposedSettings()),
        configFiles: getDiagsXCConfigFiles(for: xcodeTarget, genOptions:
            genOptions),
        sources: sources,
        dependencies: Array(Set(deps + linkedDeps)),
        prebuildScripts: prebuildScripts,
        postbuildScripts: postbuildScripts,
        scheme: nil,
        legacy: nil
    )
}

