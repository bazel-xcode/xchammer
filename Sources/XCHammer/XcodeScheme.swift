//
//  XcodeScheme.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import xcproj

public enum BuildType: String, Codable {
    case running, testing, profiling, archiving, analyzing, all
    public static var `default`: [BuildType] = [.running, .testing, .archiving, .analyzing]
    public static var indexing: [BuildType] = [.testing, .analyzing, .archiving]
    public static var testOnly: [BuildType] = [.testing, .analyzing]
}

/// XcodeScheme
/// We write schemes with xcproj directly
public struct XcodeScheme: Equatable, Codable {
    public var name: String
    public var build: Build
    public var run: Run?
    public var archive: Archive?
    public var analyze: Analyze?
    public var test: Test?
    public var profile: Profile?

    public init(name: String, build: Build, run: Run? = nil, test: Test? = nil, profile: Profile? = nil, analyze: Analyze? = nil, archive: Archive? = nil) {
        self.name = name
        self.build = build
        self.run = run
        self.test = test
        self.profile = profile
        self.analyze = analyze
        self.archive = archive
    }

    public init(name: String, targets: [BuildTarget], debugConfig: String, releaseConfig: String) {
        self.init(name: name,
                  build: .init(targets: targets),
                  run: .init(config: debugConfig),
                  test: .init(config: debugConfig),
                  profile: .init(config: releaseConfig),
                  analyze: .init(config: debugConfig),
                  archive: .init(config: releaseConfig))
    }

    public struct ExecutionAction: Codable, Equatable {
        public var script: String
        public var name: String
        public var settingsTarget: String?

        public init(name: String, script: String, settingsTarget: String?) {
            self.name = name
            self.script = script
            self.settingsTarget = settingsTarget
        }

        public static func == (lhs: ExecutionAction, rhs: ExecutionAction) -> Bool {
            return lhs.name == rhs.name && lhs.script == rhs.script && lhs.settingsTarget == rhs.settingsTarget
        }
    }

    public struct Build: Codable, Equatable {
        public var targets: [BuildTarget]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public var parallelizeBuild: Bool
        public var buildImplicitDependencies: Bool
        public init(
            targets: [BuildTarget],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = [],
            parallelizeBuild: Bool = true,
            buildImplicitDependencies: Bool = true
        ) {
            self.targets = targets
            self.preActions = preActions
            self.postActions = postActions
            self.parallelizeBuild = parallelizeBuild
            self.buildImplicitDependencies = buildImplicitDependencies
        }

        public static func == (lhs: Build, rhs: Build) -> Bool {
            return lhs.targets == rhs.targets &&
                lhs.preActions == rhs.postActions &&
                lhs.postActions == rhs.postActions &&
                lhs.parallelizeBuild == rhs.parallelizeBuild &&
                lhs.buildImplicitDependencies == rhs.buildImplicitDependencies
        }
    }

    public struct Run: Equatable, Codable {
        public var config: String
        public var commandLineArguments: [String: Bool]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(
            config: String,
            commandLineArguments: [String: Bool] = [:],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = []
        ) {
            self.config = config
            self.commandLineArguments = commandLineArguments
            self.preActions = preActions
            self.postActions = postActions
        }

        public static func == (lhs: Run, rhs: Run) -> Bool {
            return lhs.config == rhs.config &&
                lhs.commandLineArguments == rhs.commandLineArguments &&
                lhs.preActions == rhs.postActions &&
                lhs.postActions == rhs.postActions
        }
    }

    public struct Test: Equatable, Codable {
        public var config: String
        public var gatherCoverageData: Bool
        public var commandLineArguments: [String: Bool]
        public var targets: [String]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(
            config: String,
            gatherCoverageData: Bool = false,
            commandLineArguments: [String: Bool] = [:],
            targets: [String] = [],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = []
        ) {
            self.config = config
            self.gatherCoverageData = gatherCoverageData
            self.commandLineArguments = commandLineArguments
            self.targets = targets
            self.preActions = preActions
            self.postActions = postActions
        }

        public static func == (lhs: Test, rhs: Test) -> Bool {
            return lhs.config == rhs.config &&
                lhs.commandLineArguments == rhs.commandLineArguments &&
                lhs.gatherCoverageData == rhs.gatherCoverageData &&
                lhs.targets == rhs.targets &&
                lhs.preActions == rhs.postActions &&
                lhs.postActions == rhs.postActions
        }
    }

    public struct Analyze: Equatable, Codable {
        public let config: String
        public init(config: String) {
            self.config = config
        }

        public static func == (lhs: Analyze, rhs: Analyze) -> Bool {
            return lhs.config == rhs.config
        }
    }

    public struct Profile: Equatable, Codable {
        public let config: String
        public let commandLineArguments: [String: Bool]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(config: String,
                    commandLineArguments: [String: Bool] = [:],
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = []) {
            self.config = config
            self.commandLineArguments = commandLineArguments
            self.preActions = preActions
            self.postActions = postActions
        }

        public static func == (lhs: Profile, rhs: Profile) -> Bool {
            return lhs.config == rhs.config
                && lhs.commandLineArguments == rhs.commandLineArguments
                && lhs.preActions == rhs.postActions
                && lhs.postActions == rhs.postActions
        }
    }

    public struct Archive: Equatable, Codable {
        public let config: String
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(config: String,
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = []) {
            self.config = config
            self.preActions = preActions
            self.postActions = postActions
        }

        public static func == (lhs: Archive, rhs: Archive) -> Bool {
            return lhs.config == rhs.config &&
                lhs.preActions == rhs.postActions &&
                lhs.postActions == rhs.postActions
        }
    }

    public struct BuildTarget: Equatable, Codable {
        public let target: String
        public let buildTypes: [BuildType]

        /// Xcode project relative to the scheme container
        /// i.e. Some.xcodeproj
        public let project: String

        /// Name of the actual product
        /// i.e. Some.app
        public let productName: String

        public init(target: String, project: String, productName:
                String, buildTypes: [BuildType] = [BuildType.all]) {
            self.target = target
            self.buildTypes = buildTypes
            self.productName = productName
            self.project = project
        }

        public static func == (lhs: BuildTarget, rhs: BuildTarget) -> Bool {
            return (lhs.target == rhs.target 
                && lhs.buildTypes == rhs.buildTypes)
                && (lhs.project == rhs.project
                && lhs.productName == rhs.productName)
        }
    }

    public static func == (lhs: XcodeScheme, rhs: XcodeScheme) -> Bool {
        return lhs.build == rhs.build &&
            lhs.run == rhs.run &&
            lhs.test == rhs.test &&
            lhs.analyze == rhs.analyze &&
            lhs.profile == rhs.profile &&
            lhs.archive == rhs.archive
    }
}

// Mark - xcproj support

public func makeXCProjScheme(from scheme: XcodeScheme, project: String) -> xcproj.XCScheme {
    func getBuildEntry(_ buildTarget: XcodeScheme.BuildTarget) -> XCScheme.BuildAction.Entry {
        // It seems like Xcode doesn't actually need this
        let emptyTargetReference = ""
        let buildableReference = XCScheme.BuildableReference(
            referencedContainer: "container:\( buildTarget.project).xcodeproj",
            blueprintIdentifier: emptyTargetReference,
            buildableName: buildTarget.productName,
            blueprintName: buildTarget.target
        )

        let buildTypes = XCScheme.BuildAction.Entry.BuildFor.default
        return XCScheme.BuildAction.Entry(buildableReference: buildableReference, buildFor: buildTypes)
    }

    let testTargetNames = scheme.test?.targets ?? []
    // Assume test targets are in the same project
    let testBuildTargets = testTargetNames.map {
        XcodeScheme.BuildTarget(target: $0, project: project, productName:
                $0 + ".xctest", buildTypes: BuildType.testOnly)
    }

    let testBuildTargetEntries = testBuildTargets.map(getBuildEntry)
    let buildActionEntries: [XCScheme.BuildAction.Entry] = scheme.build.targets.map(getBuildEntry)

    func getExecutionAction(_ action: XcodeScheme.ExecutionAction) -> XCScheme.ExecutionAction {
        // ExecutionActions can require the use of build settings. Xcode allows the settings to come from a build or test target.
        let environmentBuildable = action.settingsTarget.flatMap { settingsTarget in
            return (buildActionEntries + testBuildTargetEntries)
                .first { settingsTarget == $0.buildableReference.blueprintName }?
                .buildableReference
        }
        return XCScheme.ExecutionAction(scriptText: action.script, title: action.name, environmentBuildable: environmentBuildable)
    }

    // There may be several scheme deps - find the first matching one by
    // convention
    let runnableEntry = buildActionEntries.first { runnable in
        return runnable.buildableReference.blueprintName == scheme.name
    }
    let buildableReference = runnableEntry!.buildableReference
    let productRunable = XCScheme.BuildableProductRunnable(buildableReference: buildableReference)
    let buildAction = XCScheme.BuildAction(
        buildActionEntries: buildActionEntries,
        preActions: scheme.build.preActions.map(getExecutionAction),
        postActions: scheme.build.postActions.map(getExecutionAction),
        parallelizeBuild: scheme.build.parallelizeBuild,
        buildImplicitDependencies: scheme.build.buildImplicitDependencies
    )

    let testables = testBuildTargetEntries.map {
        XCScheme.TestableReference(skipped: false, buildableReference: $0.buildableReference)
    }

    let testCommandLineArgs = scheme.test.map { XCScheme.CommandLineArguments($0.commandLineArguments) }
    let launchCommandLineArgs = scheme.run.map { XCScheme.CommandLineArguments($0.commandLineArguments) }
    let profileCommandLineArgs = scheme.profile.map { XCScheme.CommandLineArguments($0.commandLineArguments) }

    let testAction = XCScheme.TestAction(
        buildConfiguration: scheme.test?.config ?? "Debug",
        macroExpansion: buildableReference,
        testables: testables,
        preActions: scheme.test?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.test?.postActions.map(getExecutionAction) ?? [],
        shouldUseLaunchSchemeArgsEnv: scheme.test?.commandLineArguments.isEmpty ?? true,
        codeCoverageEnabled: scheme.test?.gatherCoverageData ?? false,
        commandlineArguments: testCommandLineArgs,
        language: ""
    )

    let launchAction = XCScheme.LaunchAction(
        buildableProductRunnable: productRunable,
        buildConfiguration: scheme.run?.config ?? "Debug",
        preActions: scheme.run?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.run?.postActions.map(getExecutionAction) ?? [],
        commandlineArguments: launchCommandLineArgs
    )

    let profileAction = XCScheme.ProfileAction(
        buildableProductRunnable: productRunable,
        buildConfiguration: scheme.profile?.config ?? "Debug",
        preActions: scheme.profile?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.profile?.postActions.map(getExecutionAction) ?? [],
        shouldUseLaunchSchemeArgsEnv: scheme.profile?.commandLineArguments.isEmpty ?? true,
        commandlineArguments: profileCommandLineArgs
    )

    let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: scheme.analyze?.config ?? "Debug")

    let archiveAction = XCScheme.ArchiveAction(
        buildConfiguration: scheme.archive?.config ?? "Debug",
        revealArchiveInOrganizer: true,
        preActions: scheme.archive?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.archive?.postActions.map(getExecutionAction) ?? []
    )

    return XCScheme(
        name: scheme.name,
        lastUpgradeVersion: "9.2",
        version: "1.3",
        buildAction: buildAction,
        testAction: testAction,
        launchAction: launchAction,
        profileAction: profileAction,
        analyzeAction: analyzeAction,
        archiveAction: archiveAction
    )
}

