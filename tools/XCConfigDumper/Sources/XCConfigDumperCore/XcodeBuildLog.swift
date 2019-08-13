//
//  XcodeBuildParser.swift
//  XCConfigDumper
//
//  Created by Vlad Solomenchuk on 8/9/19.
//

import Foundation

private func parse(log: String) -> [Record] {
    let lines = log.split(separator: "\n")
    return lines.map { Record(line: String($0)) }
}

public struct XcodeBuildLog {
    let records: [Record]

    public init(log: String) {
        records = parse(log: log)
    }
}

public extension XcodeBuildLog {
    func getAllDiagnosticParameters() -> Set<Field> {
        Set(records.filter { $0.isObjcCompiler }.map { $0.fields }.flatMap { $0 }.filter {
            if case Field.w = $0 {
                return true
            } else {
                return false
            }
        })
    }
}
