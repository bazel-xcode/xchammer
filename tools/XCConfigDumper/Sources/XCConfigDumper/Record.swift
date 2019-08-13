//
//  Line.swift
//  XCConfigDumper
//
//  Created by Vlad Solomenchuk on 8/9/19.
//

import Foundation

private func tokenize(text: String) -> [String] {
    var result = [String]()
    var accumulator = ""
    var quote: Character = "\0"
    var escape = false

    for c in text {
        if escape {
            // start escape
            escape = false
            accumulator.append(c)
        } else if c == "\\" {
            escape = true
        } else if (quote == "\0" && c == "\'") ||
            (quote == "\0" && c == "\"") {
            // start quoted sequence
            quote = c
        } else if (quote == "\'" && c == "\'") ||
            (quote == "\"" && c == "\"") {
            // end quoted sequence
            quote = "\0"
        } else if !c.isWhitespace || quote != "\0" {
            // accumulate character (which is either non-whitespace or quoted)
            accumulator.append(c)
        } else {
            // evict accumulator
            if !accumulator.isEmpty {
                result.append(accumulator)
                accumulator = ""
            }
        }
    }

    if !accumulator.isEmpty {
        result.append(accumulator)
        accumulator = ""
    }
    return result
}

public enum Field {
    case unknown(String)
    case compiler(String)
    case x(String)
    case objc(String)
    case w(String)

    init(rawValue: String) {
        if rawValue.hasSuffix("clang") {
            self = .compiler(rawValue)
        } else if rawValue.hasPrefix("-W") {
            self = .w(rawValue)
        } else {
            switch rawValue {
            case "-x":
                self = .x(rawValue)
            case "objective-c":
                self = .objc(rawValue)
            default:
                self = .unknown(rawValue)
            }
        }
    }
}

extension Field: Equatable {}
extension Field: Hashable {}

public struct Record {
    public let fields: [Field]

    public init(line: String) {
        fields = tokenize(text: line).map { Field(rawValue: $0) }
    }
}

public extension Record {
    var isCompiler: Bool {
        if case Field.compiler = fields.first ?? .unknown("") {
            return true
        } else {
            return false
        }
    }

    var isObjcCompiler: Bool {
        guard case Field.compiler = fields.first ?? .unknown("") else { return false }
        var isXFound = false
        for f in fields {
            if isXFound, case Field.objc = f {
                return true
            }
            if case Field.x = f {
                isXFound = true
            } else {
                isXFound = false
            }
        }

        return false
    }
}
