//
//  XCHammer.swift
//  XCHammer
//
//  Created by Brandon Kase on 10/27/17.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation

// TODO: Use Dictionary(_:uniqueingKeysWith) if this is on Swift 4
extension Dictionary {
    static func from<S: Sequence>(_ tuples: S) -> Dictionary where S.Iterator.Element == (Key, Value) {
        return tuples.reduce([:]) { acc, b in
            var mut = acc
            mut[b.0] = b.1
            return mut
        }
    }
}

