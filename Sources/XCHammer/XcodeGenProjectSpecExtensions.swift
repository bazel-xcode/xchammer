//
//  XcodeGenProjectSpecExtensions.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import ProjectSpec

extension ProjectSpec.Dependency : Hashable {
    public var hashValue: Int {
        return reference.hashValue
    }
}

extension ProjectSpec.TargetSource : Hashable {
    init(path: String, compilerFlags: [String]? = []) {
        self.init(path: path, name: nil, compilerFlags: compilerFlags
                ?? [])
    }
    public var hashValue: Int {
        return path.hashValue
    }
}

extension ProjectSpec.BuildScript {
    init(path: String?, script: String, name: String? = nil) {
        self.init(script: .script(script), name: name, inputFiles: [],
                outputFiles: [], shell: nil, runOnlyWhenInstalling: false)
    }
}

