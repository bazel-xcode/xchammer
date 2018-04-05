//
//  Generator.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import PathKit
import Result
import ProjectSpec
import XcodeGenKit
import xcproj
import TulsiGenerator

/// Internal struct to help building out the `Spec`
private struct XcodeGenTarget {
    let xcodeTarget: XcodeTarget
    let target: XCGTarget
}

extension XCHammerConfig {
    var buildTargetLabels: [BuildLabel] {
        return targets.map { BuildLabel($0) }
    }
}

enum Generator {
    static let BazelPreBuildTargetName = "GeneratedFiles"
    static let UpdateXcodeProjectTargetName = "UpdateXcodeProject"

    /// The current version of the generator
    /// @note any non forward or backward compatible changes to the CLI
    /// arguments or UpdateXcodeProject infra MUST bump this
    /// @note this version is written into the `XCHAMMER_DEPS_HASH` build setting
    /// the version can be extracted with a simple search: i.e.
    /// grep -m 1 XCHAMMER_DEPS_HASH $PROJ | sed 's,.*version:\(.*\):.*,\1,g'
    public static let BinaryVersion = "0.1.5"

    /// Used to store the `depsHash` into the project
    static let DepsHashSettingName = "XCHAMMER_DEPS_HASH"

    private static func makeTargets(targetMap: XcodeTargetMap, genOptions: XCHammerGenerateOptions) -> [String: XcodeGenTarget] {
        let profiler = XCHammerProfiler("convert_targets")
        defer {
            profiler.logEnd(true)
        }

        let entries: [XcodeGenTarget] = targetMap.includedTargets.flatMap {
            xcodeTarget in
            guard let target = makeXcodeGenTarget(from: xcodeTarget) else {
                return nil
            }
            return XcodeGenTarget(xcodeTarget: xcodeTarget, target: target)
        }
        return Dictionary.from(entries.map { xcodeGenTarget in
                (xcodeGenTarget.xcodeTarget.xcTargetName, xcodeGenTarget)})
    }

    private static func makeBazelPreBuildTarget(labels: [BuildLabel], genOptions:
            XCHammerGenerateOptions) -> XCGTarget {
        let bazel = genOptions.bazelPath.string
        let retrySh = XCHammerAsset.retry.getPath(underProj: genOptions.outputProjectPath)
        // We retry.sh the bazel command so if Xcode updates, the build still works
        let argStr = "-c '[[ \"$(ACTION)\" == \"clean\" ]] && (\(bazel) clean) || (\(retrySh) \(bazel) build --experimental_show_artifacts \(labels.map{ $0.value }.joined(separator: " ")))'"
        let target = XCGTarget(
            name: BazelPreBuildTargetName,
            type: PBXProductType.none,
            platform: Platform.iOS,
            settings: XCGSettings(dictionary: [String: Any]()),
            configFiles: [:],
            sources: [],
            dependencies: [],
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: nil,
            // TODO: (jerry) Fix missing initializer visibility
            legacy: try! XCGLegacyTarget(jsonDictionary: [
                "toolPath": "/bin/bash",
                "arguments": argStr,
                "passSettings": true,
                "workingDirectory": genOptions.workspaceRootPath.string
            ])
        )
        return target
    }

    private static func makeUpdateXcodeProjectTarget(genOptions:
            XCHammerGenerateOptions, projectPath: Path, depsHash: String) -> XCGTarget {
        // Use whatever command and XCHammer this project was built with
        let generateCommand = CommandLine.arguments.filter { $0 != "--force" }

        let genStatusPath: String
        if let xcworkspacePath = genOptions.xcworkspacePath {
            genStatusPath = XCHammerAsset.genStatus.getPath(underProj:
                    xcworkspacePath)
        } else {
            genStatusPath = XCHammerAsset.genStatus.getPath(underProj:
                    genOptions.outputProjectPath)
        }

        // Exit with a non 0 status to ensure Xcode reloads the project ( by
        // forcing another build in the future )
        // Determine state by comparing timestamps of the script.
        let updateScript = """
        # This file is governed by XCHammer
        set -e

        if [[ "\(BinaryVersion)" != "\(CommandLine.arguments[0]) --version" ]]; then 
            echo "warning: XCHammer version mismatch"
        fi

        if [[ $ACTION == "clean" ]]; then
            exit 0
        fi

        PREV_STAT=`stat -f %c "\(genStatusPath)"`
        \(generateCommand.joined(separator: " "))
        STAT=`stat -f %c "\(genStatusPath)"`
        if [[ "$PREV_STAT" != "$STAT" ]]; then
            echo "error: Xcode project was out-of-date so we updated it for you! Please build again."
            exit 1
        fi
        """
        // Write to the temp path, reference the actual path
        // 555 means readable and executable
        let scriptAttrs: [String: Any] =
        [FileAttributeKey.posixPermissions.rawValue: 0o555]
        let updateScriptTempPath = XCHammerAsset.updateScript.getPath(underProj:
                projectPath)
        guard FileManager.default.createFile(atPath: updateScriptTempPath,
                contents: updateScript.data(using: .utf8), attributes:
                scriptAttrs) else {
             fatalError("Can't write update script")
        }
        let updateScriptPath = XCHammerAsset.updateScript.getPath(underProj:
                genOptions.outputProjectPath)

        let argStr = "-c \(updateScriptPath)"

        let target = XCGTarget(
            name: UpdateXcodeProjectTargetName,
            type: PBXProductType.none,
            platform: Platform.iOS,
            settings: XCGSettings(dictionary: [String: Any]()),
            configFiles: [:],
            sources: [],
            dependencies: [],
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: nil,
            // TODO: (jerry) Fix missing initializer visibility
            legacy: try! XCGLegacyTarget(jsonDictionary: [
                "toolPath": "/bin/bash",
                "arguments": argStr,
                "passSettings": true,
                "workingDirectory": genOptions.workspaceRootPath.string
            ])
        )
        return target
    }

    private static func makeSchemes(for targets: [XcodeTarget], targetMap:
            XcodeTargetMap, genOptions:
            XCHammerGenerateOptions) -> [XcodeScheme] {
        let profiler = XCHammerProfiler("make_schemes")
        defer {
            profiler.logEnd(true)
        }

        let projectByXCTargetName = genOptions.config.projects.reduce(into: [String: String]()){
            result, next in
            let projectName = next.key
            let outputProjectPath = genOptions.workspaceRootPath + Path(projectName + ".xcodeproj")
            let projectGenOptions = XCHammerGenerateOptions(workspaceRootPath:
                    genOptions.workspaceRootPath, outputProjectPath:
                    outputProjectPath, bazelPath: genOptions.bazelPath,
                    configPath: genOptions.configPath, config:
                    genOptions.config, xcworkspacePath: genOptions.xcworkspacePath)
            let targetMap = XcodeTargetMap(entryMap: targetMap.ruleEntryMap,
                genOptions: projectGenOptions)
            let allApps = targetMap.includedTargets.filter {
                $0.type == "ios_application"
            }
            
            allApps.forEach { result[$0.xcTargetName] = projectName  }
        }

        func getSchemeDeps(xcodeTarget: XcodeTarget) -> [XcodeScheme.BuildTarget] {
            if xcodeTarget.isTopLevelTestTarget,
                let testHostSetting = xcodeTarget.settings.testHost?.v {
                let testHostName = testHostSetting.components(separatedBy: "/")[2]
                return [XcodeScheme.BuildTarget(target: testHostName,
                            project: projectByXCTargetName[testHostName]!,
                            productName: testHostName + ".app")]
            }
            return []
        }

        return targets
            .flatMap { xcodeTarget in
                let type = xcodeTarget.xcType!
                let name = xcodeTarget.xcTargetName
                guard type.contains("application") || type.contains("-test") else {
                    return nil
                }

                let targetConfig = genOptions.config.getTargetConfig(for:
                    xcodeTarget.label.value)
                let commandLineArguments =
                Dictionary.from((targetConfig?.commandLineArguments ?? []).map {
                        ($0, true) })

                let buildTargets = [
                    XcodeScheme.BuildTarget(target: UpdateXcodeProjectTargetName,
                            project: genOptions.projectName, productName: ""),
                    XcodeScheme.BuildTarget(target: BazelPreBuildTargetName,
                            project: genOptions.projectName, productName: "")

                ] + getSchemeDeps(xcodeTarget: xcodeTarget) + [
                    XcodeScheme.BuildTarget(target: name,
                            project: genOptions.projectName, productName:
                            xcodeTarget.extractBuiltProductName())
                ]

                let buildPhase = XcodeScheme.Build(
                        targets: buildTargets, parallelizeBuild: false)
                
                let runPhase = XcodeScheme.Run(config: "Debug",
                        commandLineArguments: commandLineArguments)

                let testTargets: [String] = allTests(for: xcodeTarget, map:
                        targetMap)
                let testPhase = XcodeScheme.Test(config: "Debug",
                        commandLineArguments: commandLineArguments, targets:
                        testTargets)

                let profilePhase = XcodeScheme.Profile(config: "Debug",
                        commandLineArguments: commandLineArguments)
                return XcodeScheme(name: name, build: buildPhase, run: runPhase,
                        test: testPhase, profile: profilePhase)
            }
    }
    
    private static func writeProject(targetMap: XcodeTargetMap, name: String,
            genOptions: XCHammerGenerateOptions, genfileLabels: [BuildLabel],
            depsHash: String) throws {
        // Setup project asset dir
        let tempDirPath = genOptions.outputProjectPath.string + "-tmp"
        let tempProjectPath = Path(tempDirPath)
        try? FileManager.default.removeItem(atPath:
                tempDirPath)

        try? FileManager.default.copyItem(atPath: genOptions.outputProjectPath.string,
                toPath: tempProjectPath.string)

        // Persist the log
        let tempLog = NSTemporaryDirectory() + "/" + UUID().uuidString
        try? FileManager.default.moveItem(atPath: XCHammerAsset.genLog.getPath(underProj: genOptions.outputProjectPath),
                toPath: tempLog)

        try FileManager.default.createDirectory(atPath: tempProjectPath.string,
                withIntermediateDirectories: true,
                attributes: [:])

        let projAssetDir = tempProjectPath + Path("XCHammerAssets")
        try? FileManager.default.removeItem(atPath:
                projAssetDir.string)

        let outputAssetDir = tempProjectPath.string
        let basePath = getAssetBase()

        // Copy over XCHammer assets from the base dir of XCHammer
        try? FileManager.default.copyItem(atPath: basePath + "/XCHammerAssets",
                toPath: outputAssetDir + "/XCHammerAssets")

        // Workaround: We need Stub.m in place for validation. XcodeGen
        // validates the project relative to the project it creates.
        try? FileManager.default.createDirectory(atPath:
                genOptions.outputProjectPath.string + "/XCHammerAssets",
                withIntermediateDirectories: true,
                attributes: [:])

        try? FileManager.default.copyItem(atPath: tempLog,
                toPath: XCHammerAsset.genLog.getPath(underProj: tempProjectPath))

        let stubPath = XCHammerAsset.stubImp.getPath(underProj:
                genOptions.outputProjectPath)
        guard FileManager.default.createFile(atPath: stubPath,
                contents: "".data(using: .utf8), attributes: nil) else {
             fatalError("Can't write temp stub")
        }

        let allTargets: [String: XcodeGenTarget] = makeTargets(targetMap:
                targetMap, genOptions: genOptions)
        // Code gen entitlement rules and write a build file
        let entitlementRules = allTargets
            .flatMap { (name: String, xcodeGenTarget: XcodeGenTarget) in
                return xcodeGenTarget.xcodeTarget.extractExportEntitlementRule(map: targetMap)
        }

        // Write the build file header
        let relativeProjDir = genOptions.outputProjectPath.string
                .replacingOccurrences(of: genOptions.workspaceRootPath.string,
                                    with: "")
        let buildFileHdr = """
            load(\"/\(relativeProjDir)/XCHammerAssets:\(XCHammerAsset.bazelExtensions.rawValue)\", \"export_entitlements\")

            """
        let buildFile = buildFileHdr + entitlementRules
                .map { $0.toBazel() }
                .joined(separator: "\n")

        // Write the build file into project level XCHammerAssets
        let buildFilePath = XCHammerAsset.buildFile.getPath(underProj:
                tempProjectPath)
        guard FileManager.default.createFile(atPath: buildFilePath,
                contents: buildFile.data(using: .utf8), attributes: nil) else {
             fatalError("Can't write BUILD file")
        }

        let genStatusPath = XCHammerAsset.genStatus.getPath(underProj:
                tempProjectPath)
        guard FileManager.default.createFile(atPath: genStatusPath,
                contents: "".data(using: .utf8), attributes: nil) else {
             fatalError("Can't write genStatus")
        }

        // Add the entitilement rules to the queried rules
        let targetsToBuild = genfileLabels + entitlementRules
                .map { BuildLabel("/" + relativeProjDir + "/XCHammerAssets:" + $0.name) }
        let bazelPreBuildTarget = makeBazelPreBuildTarget(labels: targetsToBuild,
                genOptions: genOptions)

        let updateXcodeProjectTarget = makeUpdateXcodeProjectTarget(genOptions:
                genOptions, projectPath: tempProjectPath, depsHash: depsHash)
        
        let options = ProjectSpec.Options(
                carthageBuildPath: nil,
                createIntermediateGroups: true,
                indentWidth: 4,
                tabWidth: 4,
                usesTabs: false
            )

        // Write `depsHash` 1 time into the project. DEBUG is irrelevant - this
        // is a workaround since XcodeGen is writing settings 2x for debug and
        // release
        let debugSettingsDict: [String: Any] = [DepsHashSettingName: depsHash]
        let settings = Settings(configSettings: ["DEBUG": Settings(dictionary:
                    debugSettingsDict)])
        let project = XCGProject(
            basePath: genOptions.workspaceRootPath,
            name: name,
            targets: allTargets.map { k, v in v.target } + [
                updateXcodeProjectTarget,
                bazelPreBuildTarget
            ].sorted { $0.name < $1.name },
            settings: settings,
            settingGroups: [:],
            options: options
        )

        XCHammerLogger.shared().logInfo("Writing project")
        try ProjectWriter.write(
            project: project,
            genOptions: genOptions,
            xcodeProjPath: tempProjectPath)

        let schemes = makeSchemes(for: allTargets.values.map { $0.xcodeTarget },
                targetMap: targetMap, genOptions: genOptions)
        try ProjectWriter.write(
            schemes: schemes,
            genOptions: genOptions,
            xcodeProjPath: tempProjectPath)

        // Move the new project to the output path.
        // This needs to be atomic, or it will cause issues.
        try? FileManager.default.removeItem(atPath:
                genOptions.outputProjectPath.string)
        try FileManager.default.moveItem(atPath: tempProjectPath.string,
                toPath: genOptions.outputProjectPath.string)
    }

    /// Skip hashing children of Xcode directory like files
    private static func skipXcodeDirChild(parent: URL, url: URL) -> Bool {
	// These file types are treated like directories
	let xcodeDirLikeFileTypesAndPathComponents = ["app", "appex", "bundle",
	    "framework", "octest", "xcassets", "xcodeproj", "xcdatamodel",
	    "xcdatamodeld", "xcmappingmodel", "xctest", "xcstickers", "xpc",
	    "scnassets" ].map { ($0, "." + $0 ) }

        let firstMatch = xcodeDirLikeFileTypesAndPathComponents.lazy.first {
            (ext, dotExt) in
            if parent.pathExtension != ext &&
                url.absoluteString.contains(dotExt) {
                return true
            }
            return false
        }
        return firstMatch != nil
    }

    private static func hashEntryIncludingTimestamp(for url: URL) -> String {
        let resourceValues = try? url.resourceValues(forKeys:
                Set([.contentModificationDateKey])) 
        return "\(url.hashValue)-\(Int(resourceValues?.contentModificationDate?.timeIntervalSince1970 ?? 0))"
    }

    private static func computeHashEntries<T: Sequence>(urls: T) -> [String] {
        let hashCandidates: [URL] = urls.reduce(into: [], {
            result, next in
            guard let url = next as? URL else {
                return
            }
            guard let last = result.last else {
                result.append(url)
                return
            }
            let lastPathComponent = url.lastPathComponent
            // Skip checking directory children for these types
            if lastPathComponent == "h" || 
                lastPathComponent == "m" ||
                lastPathComponent == "mm" ||
                lastPathComponent == "hpp" ||
                lastPathComponent == "cpp" ||
                lastPathComponent == "cxx" ||
                lastPathComponent == "swift" ||
                lastPathComponent == "s" {
                result.append(url)
                return
            }
            if !skipXcodeDirChild(parent: last, url: url) {
                result.append(url)
            }
        })

        let dirHashEntries = hashCandidates.flatMap { url -> String? in 
            // We need a different hash when these files change.
            // Use a timestamp for efficiency
            if url.pathExtension == "bzl" ||
                url.lastPathComponent == "BUILD" {
                return hashEntryIncludingTimestamp(for: url)
            }
            return String(url.hashValue)
        }
        return dirHashEntries
    }

    /// Return a hash of all the files under the workspace.
    /// We rely on source filters to determine if files are relevant.
    ///
    /// Note: The algorithm is intended to be used on a single machine
    /// as it uses timestamps, and may include stray files that are not
    /// part of the build.
    ///
    /// This is preferred over any techniques combining Bazel query 
    /// and aspects for speed and parallelism.
    private static func getHash(workspaceRootPath: Path, genOptions:
            XCHammerGenerateOptions) -> String {
        let profiler = XCHammerProfiler("compute_deps_hash")
        defer {
            profiler.logEnd(true)
        }

        // Compute hash entries from the path filters
        let explicitHashEntries: [String] = genOptions.pathsSet
            .sorted()
            .flatMap {
                filterValue -> [String] in 
                if filterValue.hasSuffix("**") {
                    let component = filterValue.replacingOccurrences(of: "/**",
                            with: "")
                    let dir = (workspaceRootPath + Path(component)).url
                    let enumerator = FileManager.default.enumerator(at: dir,
                            includingPropertiesForKeys: [], options:
                            [.skipsHiddenFiles], errorHandler: { (url,
                                error) -> Bool in
                        return true
                    })!
                    return computeHashEntries(urls: enumerator)
                }
                let path = (workspaceRootPath + Path(filterValue))
                if path.isDirectory {
                    let enumerator = FileManager.default.enumerator(at:
                        path.url, includingPropertiesForKeys: [],
                        options: [.skipsHiddenFiles,
                        .skipsSubdirectoryDescendants], errorHandler: { (url,
                                error) -> Bool in
                        return true
                    })!
                    return computeHashEntries(urls: enumerator)
                }
                return computeHashEntries(urls: [path.url])
            }

        // Hash entries include the Binary version and config file
        let hashEntries = ["version:\(BinaryVersion):"] +
            [hashEntryIncludingTimestamp(for: genOptions.configPath.url)] +
            explicitHashEntries
        let hashContent = hashEntries.joined(separator: "")
        let logger = XCHammerLogger.shared()
        logger.log("hash-content: " + hashContent)
        return hashContent
    }

    enum GenerateError: Error {
        case some(Error)
    }

    static func doResult<T>(_ bl: () throws -> T) -> Result<T, GenerateError> {
        do {
          let r = try bl()
          return .success(r)
        } catch {
           return .failure(.some(error)) 
        }
    }

    private static func generateProject(genOptions: XCHammerGenerateOptions,
            ruleEntryMap: RuleEntryMap, genfileLabels: [BuildLabel], depsHash:
            String) ->
    Result<(), GenerateError> {
        do {
            let logger = XCHammerLogger.shared()
            let targetMap = XcodeTargetMap(entryMap: ruleEntryMap,
                genOptions: genOptions)
            let projectName = genOptions.outputProjectPath.lastComponentWithoutExtension
            logger.logInfo("Converting to XcodeGen specification")
            try writeProject(targetMap: targetMap, name: projectName,
                    genOptions: genOptions, genfileLabels: genfileLabels,
                    depsHash: depsHash)
            return .success()
        } catch {
            return .failure(.some(error))
        }
    }

    private static func getAssetBase() -> String {
        let assetDir = "/XCHammerAssets"
        #if Xcode
            // Xcode Swift PM integration support.
            // There is no way to correctly bundle resources in this scenario.
            let components = #file .split(separator: "/")
            let assetBase = "/" + components [0 ... components.count - 4].joined(separator: "/")
        #else
            let assetBase = Bundle.main.resourcePath!
        #endif
        guard FileManager.default.fileExists(atPath: assetBase + assetDir) else {
            fatalError("Missing XCHammerAssets")
        }
        return assetBase
    }

    private static func getDepsHashSettingValue(projectPath: Path) throws ->
        String? {
        let pbxProjPath = projectPath + Path("project.pbxproj")
        let proj = try String(contentsOf: pbxProjPath.url)
        // Avoid a semantic parse of the file.
        // Extract DepsHashSettingName = "";\n from the proj
        guard let hashRange = proj.range(of: DepsHashSettingName + ".*",
                options: .regularExpression) else {
            return nil
        }
        let beginning = proj.index(hashRange.lowerBound, offsetBy:
                DepsHashSettingName.utf8.count + 4)
        let end = proj.index(hashRange.upperBound, offsetBy: -3)
        guard beginning < end else { return nil } 
        return proj[beginning...end]
    }

    // Mark - Public

    /// Main entry point of generation.
    public static func generateProjects(workspaceRootPath: Path, bazelPath: Path,
            configPath: Path, config: XCHammerConfig, xcworkspacePath: Path?) -> Result<(),
                GenerateError> {
        // Listen to Tulsi logs. Assume this function is called 1 time
        NotificationCenter.default.addObserver(forName:
                NSNotification.Name(rawValue: TulsiMessageNotification), object:
                nil, queue: nil, using: { userInfo in
            userInfo.userInfo?["message"].map { print("Tulsi:", $0) }
            // if this key exists, it contains the bazel-specific stderr
            userInfo.userInfo?["details"].map { print($0) }
        })

        // Determine the hash state of each project
        let projectStates = Dictionary.from(config.projects.map { $0.key }.parallelMap({
            projectName -> (String, (Bool, String?)) in
            let outputProjectPath = workspaceRootPath + Path(projectName + ".xcodeproj")
            let genOptions = XCHammerGenerateOptions(workspaceRootPath:
                    workspaceRootPath, outputProjectPath:
                    outputProjectPath, bazelPath: bazelPath,
                    configPath: configPath, config: config, xcworkspacePath: xcworkspacePath)
            guard let existingHash = try? getDepsHashSettingValue(projectPath:
                    genOptions.outputProjectPath) else {
                return (projectName, (false, nil))
            }
            let hash = getHash(workspaceRootPath: genOptions.workspaceRootPath,
                    genOptions: genOptions)
            return (projectName, (existingHash == hash, hash))
        }))

        // We don't want to query Tulsi unless one of the projects need to be
        // updated, since it is slow as hell.
        let logger = XCHammerLogger.shared()
        let states = projectStates.values.filter { !$0.0 }
        guard states.count > 0 else {
            logger.logInfo("Skipping update for now")
            return .success()
        }

        let entryMapProfiler = XCHammerProfiler("read_aspects")
        // get Tulsi to give us the RuleEntryMap from our workspace
        logger.logInfo("Reading Bazel configurations")
        let ruleEntryMapResult = doResult {
            return try TulsiHooks.emitRuleEntryMap(labels:
                config.buildTargetLabels, bazelPath: bazelPath,
                workspaceRootPath: workspaceRootPath)
        }
        entryMapProfiler.logEnd(true)

        guard case let .success(ruleEntryMap) = ruleEntryMapResult else {
            return .failure(ruleEntryMapResult.error!)
        }

        guard let genfileLabels = try? BazelQueryer.genFileQuery(targets:
            config.buildTargetLabels, bazelPath: bazelPath,
            workspaceRoot: workspaceRootPath) else {
            fatalError("Can't get genfiles")
        }

        let results = config.projects.map { $0.key }.parallelMap({
            projectName -> Result<(), GenerateError> in
            let logger = XCHammerLogger.shared()
            let profiler = XCHammerProfiler("generate_project")
            let outputProjectPath = workspaceRootPath + Path(projectName + ".xcodeproj")
            defer {
                 // End profiling, flush logs
                 profiler.logEnd(true)
                 try? logger.flush(projectPath: outputProjectPath)
            }

            logger.logInfo("Generating project " + projectName)
            let genOptions = XCHammerGenerateOptions(workspaceRootPath:
                    workspaceRootPath, outputProjectPath:
                    outputProjectPath, bazelPath: bazelPath,
                    configPath: configPath, config: config, xcworkspacePath: xcworkspacePath)


            let existingState = projectStates[projectName]
            // TODO: (jerry) Propagate transitive project updates to dependees
            if existingState?.0 == true {
                logger.logInfo("Skipping update for now")
                return .success()
            }

            // Attempt to get the depsHash from the project state or recompute
            let depsHash = existingState?.1 ?? getHash(workspaceRootPath:
                    genOptions.workspaceRootPath, genOptions: genOptions)
            return generateProject(genOptions: genOptions,
                    ruleEntryMap: ruleEntryMap, genfileLabels: genfileLabels,
                    depsHash: depsHash)
        })

        // Write the genStatus into the workspace
        if let xcworkspacePath = xcworkspacePath {
            try? FileManager.default.createDirectory(atPath:
                    (xcworkspacePath + Path("XCHammerAssets")).string,
                    withIntermediateDirectories: true,
                    attributes: [:])
            let genStatusPath = XCHammerAsset.genStatus.getPath(underProj:
                    xcworkspacePath)
            guard FileManager.default.createFile(atPath: genStatusPath,
                    contents: "".data(using: .utf8), attributes: nil) else {
                 fatalError("Can't write genStatus")
            }
        }
        return results.first ?? .success()
    }
}
