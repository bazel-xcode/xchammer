//
//  BazelQueryer.swift
//  XCHammer
//
//  Created by Brandon Kase on 11/27/17.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import TulsiGenerator
import ShellOut
import PathKit

/// Final Tagless DSL for BazelQuery formulas
/// Necessary so that we don't mess up formatting strings manually
/// Primitives
protocol BazelQueryLang {
    static func binop(left: Self, op: String, right: Self) -> Self
    static func application(name: String, params: [Self]) -> Self
    static func str(_ s: String) -> Self
    static func word(_ w: String) -> Self
}

/// Helpers
extension BazelQueryLang {
    static func deps(_ word: Self) -> Self {
        return application(name: "deps", params: [word])
    }
    
    static func kind(_ which: Self, _ expr: Self) -> Self {
        return application(name: "kind", params: [which, expr])
    }
    
    static func union(lhs: Self, rhs: Self) -> Self {
        return binop(left: lhs, op: "union", right: rhs)
    }
    
    static func set(_ params: [Self]) -> Self {
        return application(name: "set", params:params)
    }
}

/// Renderer
extension String: BazelQueryLang {
    static func binop(left: String, op: String, right: String) -> String {
        return "\(left) \(op) \(right)"
    }
    
    static func application(name: String, params: [String]) -> String {
        return "\(name)(\(params.joined(separator: ",")))"
    }
    
    static func str(_ s: String) -> String {
        return "\"\(s)\""
    }
    
    static func word(_ w: String) -> String {
        return "\(w)"
    }
}

enum BazelQueryer {
    static func sourceFileDepsQueryCommand(targets: [BuildLabel], bazelPath: Path, workspaceRoot: Path) -> String {
        let query = targets.flatMap{ target in
            .kind(.str("source file"), .deps(.word(target.description)))
        }.reduce(.set([]), String.union)
        let command: String = ([
            bazelPath.string,
            "query",
            "--output=label_kind",
            "'\(query)'"
        ]).joined(separator: " ")
        return command
    }
    
    /// query bazel for any generated files the project depends on
    static func genFileQuery(targets: [BuildLabel], bazelPath: Path, workspaceRoot: Path) throws -> [BuildLabel] {
        let genfileProfiler = XCHammerProfiler("query_genfiles")
        defer {
            genfileProfiler.logEnd(true)
        }
        let kindWhitelist: [String] = [
            "entitlements",
            "module_map",
            "headermap"
        ]

        let query = targets.flatMap{ target in
            kindWhitelist.map{ rule in
                .kind(.str(rule), .deps(.word(target.description)))
            }
        }.reduce(.set([]), String.union)

        let command: String = ([
            bazelPath.string,
            "query",
            "--output=label_kind",
            "'\(query)'"
        ]).joined(separator: " ")
        let output = try ShellOut.shellOut(to: [command], at: workspaceRoot.string)
        
        return output.split(separator: "\n")
            .map{ $0.split(separator: " ").last! }
            .map{ BuildLabel(String($0)) }
    }
}

extension Array where Element == String {
    /// Concat the start to the beginning of the first element, and the end to the end of the last element
    /// Ex: ["a", "b", "c"].surroundInside("(", ")") => ["(a", "b", "c)"]
    func surroundInside(start: String, end: String) -> Array {
        return ([start + self[startIndex]] as [String]) +
            Array(dropFirst().dropLast()) +
            [self[endIndex-1] + end]
    }
}
