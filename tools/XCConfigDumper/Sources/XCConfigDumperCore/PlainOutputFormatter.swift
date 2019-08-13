//
//  PlainOutputFormatter.swift
//  XCConfigDumper
//
//  Created by Vlad Solomenchuk on 8/12/19.
//

import Foundation

public struct PlainOutputFormatter: OutputFormatter {
    public init() {}
    public func stringify<T: Sequence>(fields: T) -> String where T.Element == Field {
        return fields.filter {
            if case Field.w = $0 {
                return true
            } else {
                return false
            }
        }.map { (field) -> String? in
            if case let Field.w(value) = field {
                return value
            } else {
                return nil
            }
        }.compactMap { $0 }
            .joined(separator: "\n")
    }
}
