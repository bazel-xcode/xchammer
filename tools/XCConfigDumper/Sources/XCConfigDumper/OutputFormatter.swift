//
//  OutputFormatter.swift
//  XCConfigDumper
//
//  Created by Vlad Solomenchuk on 8/12/19.
//

import Foundation

public protocol OutputFormatter {
    func stringify<T: Sequence>(fields: T) -> String where T.Element == Field
}
