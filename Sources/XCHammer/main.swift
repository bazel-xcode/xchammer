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
import Commandant
import Result
import Yams
import ShellOut

extension Path: ArgumentProtocol {
    public static let name: String = "Path"

    public static func from(string: String) -> Path? {
        return Path(string)
    }
}

enum CommandError: Error {
    case swiftException(Error)
    case tulsiException(Error)
    case missingEnvVars(String)
    case io(Error)
}

func getHammerConfig(path: Path) throws -> XCHammerConfig {
    let data = try Data(contentsOf: URL(fileURLWithPath: path.string))
    let config = try YAMLDecoder().decode(XCHammerConfig.self, from: String(data: data, encoding: .utf8)!)
    return config
}

/// XCHammer generate options
/// 
/// Options for generation only.
/// Configuration options for Xcode projects are part of `XCHammerConfig`
struct GenerateOptions: OptionsProtocol {
    typealias ClientError = CommandError

    let configPath: Path
    let workspaceRootPath: Path
    let bazelPath: Path
    let forceRun: Bool
    let xcworkspacePath: Path?

    private static func getEnvBazelPath() throws -> Path {
        let path = try shellOut(to: "which", arguments: ["bazel"])
        return Path(path)
    }

    static func create(_ configPath: Path) -> (Path?) -> (Path?) -> (Bool) -> (Path?) -> GenerateOptions {
        return { workspaceRootPathOpt in { bazelPathOpt in {
            forceRunOpt in { xcworkspacePathOpt -> GenerateOptions in
                // Defaults to PWD
                let workspaceRootPath: Path = workspaceRootPathOpt?.normalize() ??
                    Path(FileManager.default.currentDirectoryPath)
                // If the user gave us Bazel, then use that.
                // Otherwise, try to get bazel from the env
                let bazelPath: Path
                if let normalizedBazelPath = bazelPathOpt?.normalize() {
                    bazelPath = normalizedBazelPath
                } else {
                    guard let envBazel = try? getEnvBazelPath() else {
                        fatalError("Missing Bazel")
                    }
                    bazelPath = envBazel.normalize()
                }

                return GenerateOptions(
                configPath: configPath.normalize(),
                workspaceRootPath: workspaceRootPath,
                bazelPath: bazelPath,
                forceRun: forceRunOpt,
                xcworkspacePath: xcworkspacePathOpt?.normalize()
            )
        } } } } 
    }

    static func evaluate(_ m: CommandMode) -> Result<GenerateOptions, CommandantError<ClientError>> {
        return create
            <*> m <| Argument(usage: "Path to the XCHammerConfig yaml file")
            <*> m <| Option(key: "workspace_root", defaultValue: nil,
                 usage: "The source root of the repo")
            <*> m <| Option(key: "bazel", defaultValue: nil,
                 usage: "Path to the bazel binary")
            <*> m <| Option(key: "force", defaultValue: false,
                 usage: "Force run the generator")
            <*> m <| Option(key: "xcworkspace", defaultValue: nil,
                 usage: "Path to the xcworkspace")
    }
}

struct GenerateCommand: CommandProtocol {
    let verb = "generate"
    let function = "Generate an XcodeProject"

    typealias Options = GenerateOptions

    func run(_ options: Options) -> Result<(), CommandError> {
        do {
            let config = try getHammerConfig(path: options.configPath)
            let _ = try validate(config: config, workspaceRootPath:
                    options.workspaceRootPath)
            let result = Generator.generateProjects(workspaceRootPath:
                    options.workspaceRootPath, bazelPath: options.bazelPath,
                    configPath: options.configPath, config: config,
                    xcworkspacePath: options.xcworkspacePath, force:
                    options.forceRun)
            switch result {
            case .success:
                return .success(())
            case .failure(let error):
                return .failure(.swiftException(error))
            }
        } catch {
            return .failure(.swiftException(error))
        }
    }
}

struct ProcessIpaCommand: CommandProtocol {
    let verb = "process-ipa"
    let function = "Process IPA after a build -- this is expected to be run in an environment with Xcode ENV vars"

    typealias Options = NoOptions<CommandError>

    func run(_: Options) -> Result<(), CommandError> {
        guard let builtProductsDir = ProcessInfo.processInfo.environment["BUILT_PRODUCTS_DIR"] else {
            return .failure(.missingEnvVars("$BUILD_PRODUCTS_DIR not found in the env"))
        }
        guard let codesigningFolderPath = ProcessInfo.processInfo.environment["CODESIGNING_FOLDER_PATH"] else {
            return .failure(.missingEnvVars("$CODESIGNING_FOLDER_PATH not found in the env"))
        }

        return processIpa(builtProductsDir: Path(builtProductsDir), codesigningFolderPath: Path(codesigningFolderPath))
    }
}

struct VersionCommand: CommandProtocol {
    let verb = "version"
    let function = "Print the current version"

    typealias Options = NoOptions<CommandError>
    func run(_: Options) -> Result<(), CommandError> {
        print(Generator.BinaryVersion)
        return .success(())
    }
}

func main() {
    let commands = CommandRegistry<CommandError>()
    commands.register(GenerateCommand())
    commands.register(ProcessIpaCommand())
    commands.register(VersionCommand())
    commands.register(HelpCommand(registry: commands))

    var arguments = CommandLine.arguments
    // Remove executable name
    arguments.remove(at: 0)

    func handle(error: CommandError) {
        print("------")
        print("--- EXCEPTION ---")
        print(error)
        print(error.localizedDescription)
        print("------")
    }

    commands.main(defaultVerb: "help", errorHandler: handle(error:))
}

main()
