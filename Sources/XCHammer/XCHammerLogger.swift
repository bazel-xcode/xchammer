// Copyright 2018-present, Pinterest, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import PathKit

/// Warning: this logger is not thread safe
public class XCHammerLogger {
    fileprivate static var _shared: XCHammerLogger?
    private let auxFileHandle: FileHandle?

    public init(auxPath: String) {
        auxFileHandle = FileHandle(forUpdatingAtPath: auxPath)
    }

    public static func initialize() {
        // For now write to this one
        let path = "/private/var/tmp/xchammer.log"
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }

        guard FileManager.default.createFile(atPath: path,
                contents: "".data(using: .utf8), attributes: nil) else {
             fatalError("Can't write log")
        }

        XCHammerLogger._shared = XCHammerLogger(auxPath: path)
    }

    public static func shared() -> XCHammerLogger {
        guard let logger = XCHammerLogger._shared else {
            fatalError("Logger isn't configured")
        }
        return logger
    }

    /// Log a message.
    /// `dumpToStandardOutput` is off by default since we use this logger
    /// for diagnostic purposes
    public func log(_ message: String, dumpToStandardOutput: Bool = false) {
        let formattedMessage = "XCHammer: \(message)"
        if dumpToStandardOutput {
            print(formattedMessage)
        }
    }

    public func logInfo(_ message: String) {
        log(message, dumpToStandardOutput: true)
    }

    func logMetric(metric: String, time: TimeInterval) {
        let userMessage = String(format: "** Completed %@ in %.4fs", metric,
            time)
        // Uses:
        // https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU/preview
        let traceEntry = "{ \"name\": \"\(metric)\", \"ts\": \(time) }\n"
        if let data = traceEntry.data(using: .utf8) {
            auxFileHandle?.write(data)
        }
        logInfo(userMessage)
    }
}

/// Basic instrumentation a delta between a start and end time.
/// Warning: this is is not thread safe.
public class XCHammerProfiler {
    public let name: String
    public let startDate: Date
    private(set) var endDate: Date?

    /// Init a profiler with a name
    init(_ name: String) {
        self.name = name
        self.startDate = Date()
    }

    /// Requiore all ending of a profile to be logged.
    fileprivate func end() {
        endDate = Date()
    }

    public func logEnd(_ dumpToStandardOutput: Bool = false) {
        end()
        if let endTime = endDate?.timeIntervalSince(startDate) {
            XCHammerLogger.shared().logMetric(metric: self.name, time: endTime)
        }
    }
}

