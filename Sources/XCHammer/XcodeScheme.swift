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

import XcodeProj

public enum BuildType: String, Codable {
    case running, testing, profiling, archiving, analyzing, all
    public static var `default`: [BuildType] = [.running, .testing, .archiving, .analyzing]
    public static var indexing: [BuildType] = [.testing, .analyzing, .archiving]
    public static var testOnly: [BuildType] = [.testing, .analyzing]
}

public typealias ExecutionAction = XCHammerSchemeActionConfig.ExecutionAction
public typealias EnvironmentVariable = XCHammerSchemeActionConfig.EnvironmentVariable

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
    }

    public struct Run: Equatable, Codable {
        public var config: String
        public var commandLineArguments: [String: Bool]
        public var environmentVariables: [EnvironmentVariable]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(
            config: String,
            commandLineArguments: [String: Bool] = [:],
            environmentVariables: [EnvironmentVariable] = [],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = []
        ) {
            self.config = config
            self.commandLineArguments = commandLineArguments
            self.environmentVariables = environmentVariables
            self.preActions = preActions
            self.postActions = postActions
        }
    }

    public struct Test: Equatable, Codable {
        public var config: String
        public var gatherCoverageData: Bool
        public var commandLineArguments: [String: Bool]
        public var environmentVariables: [EnvironmentVariable]
        public var targets: [String]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(
            config: String,
            gatherCoverageData: Bool = false,
            commandLineArguments: [String: Bool] = [:],
            environmentVariables: [EnvironmentVariable] = [],
            targets: [String] = [],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = []
        ) {
            self.config = config
            self.gatherCoverageData = gatherCoverageData
            self.commandLineArguments = commandLineArguments
            self.environmentVariables = environmentVariables
            self.targets = targets
            self.preActions = preActions
            self.postActions = postActions
        }
    }

    public struct Analyze: Equatable, Codable {
        public let config: String
        public init(config: String) {
            self.config = config
        }
    }

    public struct Profile: Equatable, Codable {
        public let config: String
        public let commandLineArguments: [String: Bool]
        public var environmentVariables: [EnvironmentVariable]
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]
        public init(config: String,
                    commandLineArguments: [String: Bool] = [:],
                    environmentVariables: [EnvironmentVariable] = [],
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = []) {
            self.config = config
            self.commandLineArguments = commandLineArguments
            self.environmentVariables = environmentVariables
            self.preActions = preActions
            self.postActions = postActions
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
    }
}

// Mark - xcproj support

public func makeXCProjScheme(from scheme: XcodeScheme, project: String) -> XCScheme {
    func getBuildEntry(_ buildTarget: XcodeScheme.BuildTarget) -> XCScheme.BuildAction.Entry {
        // It seems like Xcode doesn't actually need this
        let buildableReference = XCScheme.BuildableReference(
            referencedContainer: "container:\( buildTarget.project).xcodeproj",
            blueprint: PBXTarget(name: buildTarget.target),
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

    func getExecutionAction(_ action: ExecutionAction) -> XCScheme.ExecutionAction {
        // ExecutionActions can require the use of build settings. Xcode allows the settings to come from a build or test target.
        let entries = (buildActionEntries + testBuildTargetEntries)
        var environmentBuildable = action.settingsTarget.flatMap {
            settingsTarget -> XCScheme.BuildableReference? in
            return entries.first { settingsTarget == $0.buildableReference.blueprintName }?
                .buildableReference
        }
        // If there is no reasonable settingsTarget, then try to find a sensible
        // default
        if environmentBuildable == nil {
            let name = scheme.name
            environmentBuildable = entries.first { entry in
                if name == entry.buildableReference.blueprintName {
                    return true
                }
                if (name + "-bazel") == entry.buildableReference.blueprintName {
                    return true
                }
                return false
            }?.buildableReference
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
    
    let testEnvironmentVariables = scheme.test?.environmentVariables
        .compactMap { XCScheme.EnvironmentVariable(variable: $0.variable, value:
                $0.value, enabled: $0.enabled) }
    let launchEnvironmentVariables = scheme.run?.environmentVariables
        .compactMap{ XCScheme.EnvironmentVariable(variable: $0.variable, value:
                $0.value, enabled: $0.enabled) }
    let profileEnvironmentVariables = scheme.profile?.environmentVariables
        .compactMap{ XCScheme.EnvironmentVariable(variable: $0.variable, value:
                $0.value, enabled: $0.enabled) }

    let testAction = XCScheme.TestAction(
        buildConfiguration: scheme.test?.config ?? "Debug",
        macroExpansion: buildableReference,
        testables: testables,
        preActions: scheme.test?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.test?.postActions.map(getExecutionAction) ?? [],
        shouldUseLaunchSchemeArgsEnv: scheme.test?.commandLineArguments.isEmpty ?? true,
        codeCoverageEnabled: scheme.test?.gatherCoverageData ?? false,
        commandlineArguments: testCommandLineArgs,
        environmentVariables: testEnvironmentVariables,
        language: ""
    )

    let launchAction = XCScheme.LaunchAction(
        runnable: productRunable,
        buildConfiguration: scheme.run?.config ?? "Debug",
        preActions: scheme.run?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.run?.postActions.map(getExecutionAction) ?? [],
        commandlineArguments: launchCommandLineArgs,
        environmentVariables: launchEnvironmentVariables
    )

    let profileAction = XCScheme.ProfileAction(
        buildableProductRunnable: productRunable,
        buildConfiguration: scheme.profile?.config ?? "Debug",
        preActions: scheme.profile?.preActions.map(getExecutionAction) ?? [],
        postActions: scheme.profile?.postActions.map(getExecutionAction) ?? [],
        shouldUseLaunchSchemeArgsEnv: scheme.profile?.commandLineArguments.isEmpty ?? true,
        commandlineArguments: profileCommandLineArgs,
        environmentVariables: profileEnvironmentVariables
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

