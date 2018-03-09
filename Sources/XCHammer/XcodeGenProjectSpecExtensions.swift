//
//  XcodeGenProjectSpecExtensions.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import ProjectSpec

/// XcodeGen ProjectSpec type workaround
/// XcodeGen uses a name of a struct as their module name, so we can't
/// correctly use namespaced imports.
/// We should fix this in XcodeGen, so we can use ProjectSpec.__TYPE__
/// TODO: (jerry) Fix this when realted PR's land

public typealias XCGProject = ProjectSpec
public typealias XCGTargetSource = TargetSource
public typealias XCGSettings = Settings
public typealias XCGDependency = Dependency
public typealias XCGTarget = Target
public typealias XCGBuildScript = BuildScript
public typealias XCGOptions = ProjectSpec.Options
public typealias XCGLegacyTarget = LegacyTarget

extension XCGDependency : Hashable {
    public var hashValue: Int {
        return reference.hashValue
    }
}

extension XCGTargetSource : Hashable {
    init(path: String, compilerFlags: [String]? = []) {
        self.init(path: path, name: nil, compilerFlags: compilerFlags
                ?? [])
    }
    public var hashValue: Int {
        return path.hashValue
    }
}

extension XCGBuildScript {
    init(path: String?, script: String, name: String? = nil) {
        self.init(script: .script(script), name: name, inputFiles: [],
                outputFiles: [], shell: nil, runOnlyWhenInstalling: false)
    }
}

