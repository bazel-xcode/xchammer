//
//  CompilationDatabbaseBuilder.swift
//  CompilationDatabaseToolkit
//
//  Created by Jerry Marino on 12/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

import Foundation

public func GetArguments() -> BuildArguments {
    let defaults = UserDefaults.standard
    let xcodeTargets = defaults.string(forKey: "xcodetargets")!.components(separatedBy: ",")
    let schemeName = xcodeTargets[0]
    let bazelTargets = defaults.string(forKey: "bazeltargets")!.components(separatedBy: ",")
    let workspaceName = defaults.string(forKey: "xcodeworkspace")
    let projectName = defaults.string(forKey: "xcodeproject")
    let sourceRoot = defaults.string(forKey: "srcroot")!
    return BuildArguments(schemeName: schemeName,
                          sourceRoot: sourceRoot,
                          projectName: projectName,
                          workspaceName: workspaceName,
                          xcodeTargets: xcodeTargets,
                          bazelTargets: bazelTargets)
}

public func GetNormalizedPath(path: String) -> String {
    let args = GetArguments()
    return path.replacingOccurrences(of: args.sourceRoot, with: "")
}


public func JSONDB(atPath path: String) -> CompilationDatabase {
    guard
        let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
        let JSONFile = try? JSONSerialization.jsonObject(with: data,
                                                         options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSON = JSONFile as? [[String: Any]] else {
            fatalError("Invalid comp DB at path:" + path)
    }
    let db = JSONCompilationDatabase(json: JSON)!
    return db
}


public extension KWBackgroundTask {
    /// Return Standard Output as a String
    public var standardOutputAsString: String {
        return String(data: standardOutputData, encoding: String.Encoding.utf8) ?? ""
    }
}

// MARK: - Options

public let BazelBinPath = "tools/bazelwrapper"
public let DefaultTaskTimeout = TimeInterval(60 * 60 * 2000.0)

// FIXME: this is a stray argument
public let skipClean = false

public struct BuildArguments {
    public let schemeName: String
    public let sourceRoot: String
    public let projectName: String?
    public let workspaceName: String?
    public let xcodeTargets: [String]
    public let bazelTargets: [String]
    
    /// Skip builds ( useful for development )
    public let skipBuild = false
}


public class XCCompilationDatabaseBuilder {
    let schemeName: String
    let xcodeTargets: [String]
    let sourceRoot: String
    let projectName: String?
    let workspaceName: String?
    let skipBuild: Bool

    public init(schemeName: String,
                xcodeTargets: [String],
                sourceRoot: String,
                projectName: String?,
                workspaceName: String?,
                skipBuild: Bool) {
        self.sourceRoot = sourceRoot
        self.xcodeTargets = xcodeTargets
        self.projectName = projectName
        self.workspaceName = workspaceName
        self.schemeName = schemeName
        self.skipBuild = skipBuild
    }

    public func xcClean() {
        let cleanCommand = KWBackgroundTask(command: "/bin/sh",
                                            arguments: ["-c", "cd " + sourceRoot + "; rm -rf build 2>&1"],
                                            timeout: DefaultTaskTimeout)
        cleanCommand.launchAndWaitForExit()
        assert(cleanCommand.terminationStatus == 0)
    }

    /// Get an Xcode compilation database
    /// This uses data structures in Xcode due to the fact that:
    /// - There is no way to reliably get this database for Xcode projects
    ///  with non trivial standard outputs.
    ///
    /// - There is no way to get a comp db for a single target without deps.
    ///
    /// Please find more information about this here:
    /// http://Jerry Marinomarino.com/2017/05/16/reversing-xcodes-build-graph.html
    public func getXCCompDB() -> Any {
        var projectOrWorkspaceOption: String?
        
        if let projectName = projectName {
            projectOrWorkspaceOption = " -project " + sourceRoot + projectName
        }
        if let workspaceName = workspaceName {
            projectOrWorkspaceOption = " -workspace " + sourceRoot + workspaceName
        }
        
        if !skipClean {
            xcClean()
        }

        // Do an Xcode build here.
        let buildXCCommand = "xcodebuild -dry-run -configuration Debug " +
            projectOrWorkspaceOption! + " " +
            " -scheme " + schemeName +
            " -sdk iphonesimulator " +
            " -derivedDataPath " + sourceRoot + "/build"
        
        // We want to print the command before skipping
        print("XcodeBuildCommand: "  + buildXCCommand)
        if skipBuild {
            let compDB = collectXCBuildGraphs(buildDir: sourceRoot +
                "/build/Build/Intermediates.noindex/")
            return compDB
        }
        
        let xcBuildCommand = KWBackgroundTask(command: "/bin/sh",
                                              arguments: ["-c", "" + "cd " + sourceRoot + "; " + buildXCCommand + ""],
                                              timeout: DefaultTaskTimeout)
        
        xcBuildCommand.launchAndWaitForExit()
        if xcBuildCommand.terminationStatus != 0 {
            print("BuildCommandFailed")
            fatalError("XcodeBuildOut:" + xcBuildCommand.standardOutputAsString)
        }
        
        let compDB = collectXCBuildGraphs(buildDir: sourceRoot +
            "/build/Build/Intermediates.noindex/")
        return compDB
    }
    
    func collectXCBuildGraphs(buildDir: String) -> CompilationDatabase {
        let find = KWBackgroundTask(command: "/usr/bin/find",
                                    arguments: [
                                        buildDir,
                                        "-type",
                                        "f",
                                        "-name",
                                        "*dgph",
                                        ],
                                    timeout: DefaultTaskTimeout)
        find.launchAndWaitForExit()
        
        if find.terminationStatus != 0 {
            fatalError("Can't find anything")
        }
        
        let dgphs = find.standardOutputAsString.split(separator: "\n")
        var outDB: CompilationDatabase = JSONCompilationDatabase()
        for dgph in dgphs {
            let components = dgph.split(separator: "/")
            let subComponents = components[0 ..< components.count - 1]
            // This needs to conditionally check if the path is absolute
            let dir = "/" + subComponents.joined(separator: "/")
            let db = XCCompilationDatabase(buildDirectory: dir)
            outDB = mergeCompDB(outDB, db)
        }
        return outDB
    }
}

public class BazelCompilationDatabaseBuilder {
    let bazelTargets: [String]
    let sourceRoot: String
    let skipBuild: Bool
    
    public init(bazelTargets: [String],
                sourceRoot: String,
                skipBuild: Bool) {
        self.bazelTargets = bazelTargets
        self.sourceRoot = sourceRoot
        self.skipBuild = skipBuild
    }

    public func bazelClean() {
        let cleanCommand = KWBackgroundTask(command: "/bin/sh",
                                            arguments: ["-c", "cd " + sourceRoot + "; " + BazelBinPath + " clean 2>&1"],
                                            timeout: DefaultTaskTimeout)
        cleanCommand.launchAndWaitForExit()
        assert(cleanCommand.terminationStatus == 0)
    }
    
    /// Do a bazel build of the pod and export the CompDB
    /// Note: This assumes that the `srcRoot` has a few tools including:
    /// - extra actions to export the compiler invocations
    /// - a python script to generate a DB from those invocations
    public func getBazelCompDB() -> Any {
        let targets = bazelTargets.map { "'" + $0 + "' " }.joined(separator: "")
        let bazelBuildCommandStr = BazelBinPath + " build " +
            " --action_env=BAZEL_WORKSPACE_DIR=" + sourceRoot +
            " --ios_minimum_os=9.0 " +
            " --verbose_failures " +
            " --announce_rc " +
            " --config=ios_x86_64" +
            " --spawn_strategy=standalone " +
            " --compilation_mode=dbg " +
            " --define CONFIGURATION=debug " +
            " --experimental_show_artifacts " +
            targets +
            "--experimental_action_listener=//tools/actions:generate_compile_commands_listener " +
        "2>&1 | cat > /tmp/comp_log"
        print("BazelCommand", bazelBuildCommandStr)
        
        // We want to print the BazelCommand before skipping..
        if skipBuild {
            let dbFile = sourceRoot + "build/compile_commands.json"
            let db = JSONDB(atPath: dbFile)
            return db
        }
        
        if !skipClean {
            // Since the extra_actions run incrementally, it is be required to do
            // bazel cleans.
            bazelClean()
        }
        
        // need to CD into workspace root first
        let bazelShellCommand = "cd " + sourceRoot + "; " + bazelBuildCommandStr
        let bazelBuildCommand = KWBackgroundTask(command: "/bin/sh",
                                                 arguments: ["-c", bazelShellCommand],
                                                 timeout: DefaultTaskTimeout)
        bazelBuildCommand.launchAndWaitForExit()
        
        if bazelBuildCommand.terminationStatus != 0 {
            print("BazelBuildOut:", bazelBuildCommand.standardOutputAsString)
            fatalError("BuildCommandFailed")
        }
        
        let collectCompDBJSONCommand = "python " + sourceRoot + "tools/actions/generate_compile_commands_json.py"
        let bazelCompDBCommand = KWBackgroundTask(command: "/bin/sh",
                                                  arguments: ["-c", "cd " + sourceRoot + "; " + collectCompDBJSONCommand],
                                                  timeout: DefaultTaskTimeout)
        bazelCompDBCommand.launchAndWaitForExit()
        assert(bazelCompDBCommand.terminationStatus == 0)
        
        let dbFile = sourceRoot + "build/compile_commands.json"
        let db = JSONDB(atPath: dbFile)
        return db
    }
}


