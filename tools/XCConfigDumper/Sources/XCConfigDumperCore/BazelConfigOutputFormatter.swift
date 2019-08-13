//
//  XCConfigOutputFormatter.swift
//  XCConfigDumper
//
//  Created by Vlad Solomenchuk on 8/12/19.
//

import Foundation

public struct BazelConfigOutputFormatter: OutputFormatter {
    private let comment: String
    public init(comment: String) {
        self.comment = comment
    }

    public func stringify<T: Sequence>(fields: T) -> String where T.Element == Field {
        let body = fields.filter {
            if case Field.w = $0 {
                return true
            } else {
                return false
            }
        }
        .map { (field) -> String? in
            if case let Field.w(value) = field {
                return "   \"\(value)\""
            } else {
                return nil
            }
        }
        .compactMap { $0 }
        .sorted()
        .joined(separator: ",\n")

        return """
        \(comment)
        DIAG_FLAGS = [
        \(body)
        ]
        """
    }
}
