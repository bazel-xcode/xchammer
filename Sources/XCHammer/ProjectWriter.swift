//
//  ProjectWriter.swift
//  XCHammer
//
//  Created by Brandon Kase on 10/27/17.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import XcodeGenKit
import ProjectSpec
import PathKit
import xcproj

enum ProjectWriter {

    static func write(schemes schemeDefinitions: [XcodeScheme], genOptions:
            XCHammerGenerateOptions, xcodeProjPath: Path) throws {
        let projectName = genOptions.projectName

        // Promote schemes from the project level to the workspace level
        // Works around an issue with schemes dissapearing.
        // This should be an atomic operation but we don't govern the workspace writes.
        // TODO: experiment/test making workspace updates atomic
        let basePath = (genOptions.xcworkspacePath ?? xcodeProjPath) +
            Path("xcshareddata/xcschemes")
        try? FileManager.default.createDirectory(atPath: basePath.string,
                withIntermediateDirectories: true,
                attributes: [:])
        schemeDefinitions.forEach { schemeDef in
            let scheme = makeXCProjScheme(from: schemeDef, project: projectName)
            let path = basePath + Path(scheme.name + ".xcscheme")
            try! scheme.write(path: path, override: true)
        }
    }

    static func write(project xcodeGenSpec: ProjectSpec.Project, genOptions: XCHammerGenerateOptions,
            xcodeProjPath: Path) throws {
        let profiler = XCHammerProfiler("xcode_gen")
        defer {
            profiler.logEnd(true)
        }

        // generate the project from the spec
        let generator = ProjectGenerator(project: xcodeGenSpec)
        let xcproj = try generator.generateXcodeProject()
        try xcproj.write(path: xcodeProjPath)


        /*
             MyProject.xcodeproj
             ├── project.xcworkspace
             │   ├── xcshareddata
             │   │   └── WorkspaceSettings.xcsettings
         */
        // Create WorkspaceSettings.xcsettings to prevent the Xcode auto scheme creation.
        let sharedDataURL = (xcodeProjPath + "project.xcworkspace/xcshareddata").url
        let fm = FileManager.default
        try? fm.createDirectory(at: sharedDataURL, withIntermediateDirectories: false, attributes: nil)
        fm.createFile(atPath: sharedDataURL.appendingPathComponent("WorkspaceSettings.xcsettings").path,
                      contents:
                    """
                        <?xml version="1.0" encoding="UTF-8"?>
                        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                        <plist version="1.0">
                        <dict>
                            <key>IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded</key>
                            <false/>
                        </dict>
                        </plist>
                    """.data(using: .utf8),
                      attributes: nil)
    }
}
