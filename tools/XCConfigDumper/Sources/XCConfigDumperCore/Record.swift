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
    
    // evict accumulator
    func cleanup() {
        guard !accumulator.isEmpty else { return }
        
        result.append(accumulator)
        accumulator = ""
    }

    for c in text {
        if escape {
            // start escape
            escape = false
            accumulator.append(c)
        } else {
            switch c {
            case "\\":
                escape = true
            case "\'" where quote == "\0",
                 "\"" where quote == "\0":
                // start quoted sequence
                quote = c
            case "\'" where quote == "\'",
                 "\"" where quote == "\"":
                // end quoted sequence
                quote = "\0"
            default:
                if !c.isWhitespace || quote != "\0" {
                    // accumulate character (which is either non-whitespace or quoted)
                    accumulator.append(c)
                } else {
                    cleanup()
                }
            }
        }
    }

    cleanup()
    return result
}

public enum Field {
    case unknown(String)
    case clang(String)
    case x(String)
    case objc(String)
    case w(String)

    init(rawValue: String) {
        if rawValue.hasSuffix("clang") {
            self = .clang(rawValue)
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
        switch fields.first {
        case .clang:
            return true
        default:
            return false
        }
    }

    var isObjcCompiler: Bool {
        guard isCompiler else { return false }
        var isXFound = false
        for f in fields {
            switch f {
            case .objc where isXFound:
                return true
            case .x:
                isXFound = true
            default:
                isXFound = false
            }
        }

        return false
    }
}
