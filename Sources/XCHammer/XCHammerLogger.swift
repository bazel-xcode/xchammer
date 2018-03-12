//
//  XCHammerLogger.swift
//  XCHammer
//
//  Created by Jerry Marino on 3/12/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation
import PathKit

/// Warning: this logger is not thread safe
public class XCHammerLogger {
    private static let name = "XCHammer"
    private var messages: [String] = []

    /// Log a message.
    /// `dumpToStandardOutput` is off by default since we use this logger
    /// for diagnostic purposes
    public func log(_ message: String, dumpToStandardOutput: Bool = false) {
        let formattedMessage = "\(XCHammerLogger.name): \(message)"
        messages.append(formattedMessage)
        if dumpToStandardOutput {
            print(formattedMessage)
        }
    }

    /// Log a user visible info message - written to standard output
    public func logInfo(_ message: String) {
        log(message, dumpToStandardOutput: true)
    }

    /// Dump the log to a file
    public func flush(projectPath: Path) throws {
        guard let data = messages.joined(separator: "\n").data(using: .utf8) else {
            return
        }

        // Empty out messages
        messages = []

        let logPath = Path(XCHammerAsset.genLog.getPath(underProj: projectPath))
        if let updateHandle = FileHandle(forUpdatingAtPath: logPath.string) {
            defer {
                 updateHandle.closeFile()
            }

            let appendToExistingLog = {
                updateHandle.seekToEndOfFile()
                updateHandle.write(data)
            }

            // Update the hammer log. There are 3 possible secnarios
            // 1) The log exists and it is too big.
            // 2) The log exists and it is small enough to write to.
            //    Since logs can get large, we don't want to read in the entire
            //    log everytime.
            // 3) The log does not exist - create a new one.
                
            if let attrs = try? FileManager.default.attributesOfItem(atPath:
                    logPath.string),
                let baseSize = attrs[.size] as? Int {
                    // Half the file when it is over maxSize and rotate the log
                let size = baseSize + data.count
                let maxSize = 25 * 1000000
                if size > maxSize {
                    let tempLog = NSTemporaryDirectory() + "/" + UUID().uuidString
                    guard FileManager.default.createFile(atPath: tempLog, contents:
                            Data(), attributes: nil),
                        let writeHandle = FileHandle(forWritingAtPath: tempLog) else {
                        fatalError("unknown file error")
                    }

                    defer {
                        writeHandle.closeFile()
                    }

                    updateHandle.seek(toFileOffset: UInt64(maxSize / 2))
                    let front = updateHandle.readDataToEndOfFile()
                    writeHandle.write(front)
                    writeHandle.write(data)
                    try? FileManager.default.removeItem(atPath:
                    logPath.string)
                    try? FileManager.default.moveItem(atPath: tempLog, toPath:
                    logPath.string)
                } else {
                    appendToExistingLog()
                }
            } else {
                appendToExistingLog()
            }
        } else {
            // Create a new file
            try data.write(to: logPath.url, options: .atomic)
        }
    }

    /// Shared logger per thread.
    static func shared() -> XCHammerLogger {
        let threadDictionary = Thread.current.threadDictionary
        let loggerKey = "com.pinterest.xchammer.hammerlogger"
        if let logger = threadDictionary[loggerKey] {
            return logger as! XCHammerLogger
        }
        let logger = XCHammerLogger()
        threadDictionary[loggerKey] = logger
        return logger
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

