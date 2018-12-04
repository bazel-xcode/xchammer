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
    private static let name = "XCHammer"

    /// Log a message.
    /// `dumpToStandardOutput` is off by default since we use this logger
    /// for diagnostic purposes
    public func log(_ message: String, dumpToStandardOutput: Bool = false) {
        let formattedMessage = "\(XCHammerLogger.name): \(message)"
        if dumpToStandardOutput {
            print(formattedMessage)
        }
    }
    public func logInfo(_ message: String) {
        log(message, dumpToStandardOutput: true)
    }

    private static let _shared = XCHammerLogger()
    public static func shared() -> XCHammerLogger {
        return XCHammerLogger._shared
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

    /// Return a loggable description
    public func loggableDescription() -> String {
        return String(format: "** Completed %@ in %.4fs", name,
                endDate!.timeIntervalSince(startDate))
    }

    /// Requiore all ending of a profile to be logged.
    fileprivate func end() {
        endDate = Date()
    }
}

extension XCHammerProfiler {
    public func logEnd(_ dumpToStandardOutput: Bool = false) {
        end()
        XCHammerLogger.shared().log(loggableDescription(), dumpToStandardOutput: dumpToStandardOutput)
    }
}

