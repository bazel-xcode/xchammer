// Copyright 2019-present, Pinterest, Inc.
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
import Result
import ShellOut

enum XcodeBuildSystemInstaller {
    /// Installs the Xcode build system contained inside the bundle if necessary
    /// It noops quickly if the installed plist doesnt match in order to be ran
    /// inline with builds or project generation

    static let servicePath =
            "/Contents/SharedFrameworks/XCBuild.framework/PlugIns/XCBBuildService.bundle/Contents/MacOS/XCBBuildService"
    static func installIfNecessary() -> Result<(), CommandError> {
        let bundle = Bundle.main
        let buildkitBundlePath = bundle.path(forResource: "XCBuildKit", ofType: "bundle")!
        let xcodeLocatorPath =  buildkitBundlePath + "/xcode-locator"
        let installedAppDir = "/opt/XCBuildKit/XCBuildKit.app"
        let installedBinPath =  installedAppDir + "/Contents/MacOS/BazelBuildService"
        let plistPath = buildkitBundlePath + "/BuildInfo.plist"
        let pkgVersion = getVersion(path: plistPath)

        // Check each Xcode that's compatible with this version and verify if
        // it's installed
        var hasUnlinkedXcodes = false
        let cmd = xcodeLocatorPath + " 2>&1 | grep expanded=11 | sed -e 's,.*file://,,g' -e 's,/:.*,,g'"
        do {
            let resultsStr = try shellOut(to: cmd)
            // Returns an array of [/Path/To/Xcode.app/]
            let xcodes = resultsStr.split(separator: "\n")
            if xcodes.count == 0 {
                print("warning: No Xcodes installed")
            }
            let needsInstalls = xcodes.filter {
                xcode in
                let bsPath = String(xcode + servicePath)
                guard let link = try? FileManager.default.destinationOfSymbolicLink(atPath: bsPath) else {
                   return true
                }
                guard link == installedBinPath else {
                    return true
                }
                return false
            }
            hasUnlinkedXcodes = needsInstalls.count > 0
        } catch {
            return .failure(.basic(error.localizedDescription))
        }

        let installedPlistPath = installedAppDir + "/Contents/Info.plist"
        if hasUnlinkedXcodes || pkgVersion != getVersion(path: installedPlistPath) {
            print("xchammer requires install")
            let installerPath = buildkitBundlePath + "/BazelBuildServiceInstaller.pkg"
            let script = "installer -pkg \(installerPath) -target /"
            guard ShellOutWithSudo(script) == 0 else {
                return .failure(.basic("failed to install. please see /var/log/install.log for more info"))
            }
        }
        return .success(())
    }

    static func getVersion(path: String) -> String? {
        guard let plistXML = FileManager.default.contents(atPath: path) else {
            return nil
        }
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml
        guard let plistData: [String: AnyObject] = try? PropertyListSerialization.propertyList(from:
            plistXML, options: .mutableContainersAndLeaves,
            format: &propertyListFormat) as! [String:AnyObject] else {
            fatalError("Can't read plist")
        }
        // This is determined by the ref of xcbuildkit either built by it's
        // self, or the repository_rule that defined it.
        // https://github.com/jerrymarino/xcbuildkit/blob/master/BUILD#L101
        return plistData["BUILD_COMMIT"] as? String
    }
}

/// Disable echo to prevent exposing stdin.
/// This behaves nearly identical but swallows the newline before
/// "Sorry, please try again"
func disableEcho(fileHandle: FileHandle) -> termios {
    let struct_pointer = UnsafeMutablePointer<termios>.allocate(capacity: 1)
    var raw = struct_pointer.pointee
    struct_pointer.deallocate()

    tcgetattr(fileHandle.fileDescriptor, &raw)
    let original = raw
    raw.c_lflag &= ~(UInt(ECHO))
    raw.c_lflag &= (UInt(ECHOE |  ECHONL | ICANON | ECHOCTL))
    tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &raw);
    return original
}

func restoreEcho(fileHandle: FileHandle, originalTerm: termios) {
    var term = originalTerm
    tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &term);
}

func ShellOutWithSudo(_ script: String) -> Int32 {
    let process = Process()
    process.environment = ProcessInfo.processInfo.environment
    let stdin = Pipe()
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr
    process.standardInput = stdin
    process.launchPath = "/bin/bash"

    // Unless this is running 
    let originalTerm = disableEcho(fileHandle: FileHandle.standardInput)
    defer {
        restoreEcho(fileHandle: FileHandle.standardInput, originalTerm: originalTerm)
    }

    // Pipe fitting:
    // pipe stdin to the process stdin
    FileHandle.standardInput.readabilityHandler = {
        stdin.fileHandleForWriting.write($0.availableData)
    }

    // pipe stdout to our stdout
    stderr.fileHandleForReading.readabilityHandler = {
        FileHandle.standardError.write($0.availableData)
    }

    // pipe stderr to our stdout
    stdout.fileHandleForReading.readabilityHandler = {
        FileHandle.standardOutput.write($0.availableData)
    }
    process.arguments = ["-c", "sudo -S \(script)"] 
    process.launch()
    process.waitUntilExit()
    return process.terminationStatus
}
