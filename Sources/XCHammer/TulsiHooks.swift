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
import TulsiGenerator
import PathKit


public struct XcodeProjectRuleInfo: Codable {
    let execRoot: String
    let tulsiinfos: [String]
}

enum TulsiHooks {
    static func getWorkspaceInfo(labels: [BuildLabel], bazelPath: Path,
            workspaceRootPath: Path) throws ->
        XCHammerBazelWorkspaceInfo {
        let ungeneratedProjectName = "Some"
        let config = TulsiGeneratorConfig(projectName: ungeneratedProjectName,
                buildTargetLabels: labels,
                pathFilters: Set(),
                additionalFilePaths: [],
                options: TulsiOptionSet(),
                bazelURL: TulsiParameter(value: bazelPath.url,
                    source: .options))
        return try TulsiRuleEntryMapExtractor.extract(config:
                config, workspace: workspaceRootPath.url)
    }

    static func getWorkspaceInfoV2(labels: [BuildLabel], ruleInfo: XcodeProjectRuleInfo) throws ->
        XCHammerBazelWorkspaceInfo {
	let execRoot = ruleInfo.execRoot
	let files = Set(ruleInfo.tulsiinfos)
	let ruleEntryMap = extractRuleEntriesFromArtifacts(files,
		executionRootURL: URL(fileURLWithPath: execRoot))
	return XCHammerBazelWorkspaceInfo(bazelExecRoot: execRoot, ruleEntryMap: ruleEntryMap)
    }


  enum ExtractorError: Error {
    /// Failed to build aspects.
    case buildFailed
    /// Parsing an aspect's output failed with the given debug info.
    case parsingFailed(String)
  }

  /// Builds a list of RuleEntry instances using the data in the given set of .tulsiinfo files.
  static func extractRuleEntriesFromArtifacts(_ files: Set<String>, executionRootURL: URL) -> RuleEntryMap {
    let fileManager = FileManager.default

    func parseTulsiTargetFile(_ filename: String) throws -> RuleEntry {
      return try autoreleasepool {
        return try parseTulsiTargetFileImpl(filename)
      }
    }

    func parseTulsiTargetFileImpl(_ filename: String) throws -> RuleEntry {
      guard let data = fileManager.contents(atPath: filename) else {
        throw ExtractorError.parsingFailed("The file could not be read")
      }
      guard let dict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [String: AnyObject] else {
        throw ExtractorError.parsingFailed("Contents are not a dictionary")
      }

      func getRequiredField(_ field: String) throws -> String {
        guard let value = dict[field] as? String else {
          throw ExtractorError.parsingFailed("Missing required '\(field)' field")
        }
        return value
      }

      let ruleLabel = try getRequiredField("label")
      let ruleType = try getRequiredField("type")
      let attributes = dict["attr"] as? [String: AnyObject] ?? [:]

      func MakeBazelFileInfos(_ attributeName: String) -> [BazelFileInfo] {
        let infos = dict[attributeName] as? [[String: AnyObject]] ?? []
        var bazelFileInfos = [BazelFileInfo]()
        for info in infos {
          if let pathInfo = BazelFileInfo(info: info as AnyObject?) {
            bazelFileInfos.append(pathInfo)
          }
        }
        return bazelFileInfos
      }

      let artifacts = MakeBazelFileInfos("artifacts")
      var sources = MakeBazelFileInfos("srcs")

      // Appends BazelFileInfo objects to the given array for any info dictionaries representing
      // source code or (potential) source code containers. The directoryArtifacts set is also
      // populated as a side effect.
      var directoryArtifacts = Set<String>()
      func appendGeneratedSourceArtifacts(_ infos: [[String: AnyObject]],
                                          to artifacts: inout [BazelFileInfo]) {
        for info in infos {
          guard let pathInfo = BazelFileInfo(info: info as AnyObject?) else {
            continue
          }
          if pathInfo.isDirectory {
            directoryArtifacts.insert(pathInfo.fullPath)
          } else {
            guard let fileUTI = pathInfo.uti, fileUTI.hasPrefix("sourcecode.") else {
              continue
            }
          }
          artifacts.append(pathInfo)
        }
      }

      let generatedSourceInfos = dict["generated_files"] as? [[String: AnyObject]] ?? []
      appendGeneratedSourceArtifacts(generatedSourceInfos, to: &sources)

      var nonARCSources = MakeBazelFileInfos("non_arc_srcs")
      let generatedNonARCSourceInfos = dict["generated_non_arc_files"] as? [[String: AnyObject]] ?? []
      appendGeneratedSourceArtifacts(generatedNonARCSourceInfos, to: &nonARCSources)

      let includePaths: [RuleEntry.IncludePath]?
      if let includes = dict["includes"] as? [String] {
        includePaths = includes.map() {
          RuleEntry.IncludePath($0, directoryArtifacts.contains($0))
        }
      } else {
        includePaths = nil
      }
      let objcDefines = dict["objc_defines"] as? [String]
      let swiftDefines = dict["swift_defines"] as? [String]
      let deps = dict["deps"] as? [String] ?? []
      let dependencyLabels = Set(deps.map({ BuildLabel($0) }))
      let testDeps = dict["test_deps"] as? [String] ?? []
      let testDependencyLabels = Set(testDeps.map { BuildLabel($0) })
      let frameworkImports = MakeBazelFileInfos("framework_imports")
      let buildFilePath = dict["build_file"] as? String
      let osDeploymentTarget = dict["os_deployment_target"] as? String
      let secondaryArtifacts = MakeBazelFileInfos("secondary_product_artifacts")
      let swiftLanguageVersion = dict["swift_language_version"] as? String
      let swiftToolchain = dict["swift_toolchain"] as? String
      let swiftTransitiveModules = MakeBazelFileInfos("swift_transitive_modules")
      let objCModuleMaps = MakeBazelFileInfos("objc_module_maps")
      let moduleName = dict["module_name"] as? String
      let extensions: Set<BuildLabel>?
      if let extensionList = dict["extensions"] as? [String] {
        extensions = Set(extensionList.map({ BuildLabel($0) }))
      } else {
        extensions = nil
      }
      let bundleID = dict["bundle_id"] as? String
      let bundleName = dict["bundle_name"] as? String
      let productType = dict["product_type"] as? String

      let platformType = dict["platform_type"] as? String
      let xcodeVersion = dict["xcode_version"] as? String

      let targetProductType: PBXTarget.ProductType?

      if let productTypeStr = productType {
        // Better be a type that we support, otherwise it's an error on our end.
        if let actualProductType = PBXTarget.ProductType(rawValue: productTypeStr) {
          targetProductType = actualProductType
        } else {
          throw ExtractorError.parsingFailed("Unsupported product type: \(productTypeStr)")
        }
      } else {
        targetProductType = nil
      }

      var extensionType: String?


      let isiOSAppExtension = targetProductType?.isiOSAppExtension
      if isiOSAppExtension ?? false, let infoplistPath = dict["infoplist"] as? String {
        let plistPath = executionRootURL.appendingPathComponent(infoplistPath).path
        guard let info = NSDictionary(contentsOfFile: plistPath) else {
          throw ExtractorError.parsingFailed("Unable to load extension plist file: \(plistPath)")
        }

        guard let _extensionType = info.value(forKeyPath: "NSExtension.NSExtensionPointIdentifier") as? String else {
          throw ExtractorError.parsingFailed("Missing NSExtensionPointIdentifier in extension plist: \(plistPath)")
        }

        extensionType = _extensionType
      }

      let ruleEntry = RuleEntry(label: ruleLabel,
                                type: ruleType,
                                attributes: attributes,
                                artifacts: artifacts,
                                sourceFiles: sources,
                                nonARCSourceFiles: nonARCSources,
                                dependencies: dependencyLabels,
                                testDependencies: testDependencyLabels,
                                frameworkImports: frameworkImports,
                                secondaryArtifacts: secondaryArtifacts,
                                extensions: extensions,
                                bundleID: bundleID,
                                bundleName: bundleName,
                                productType: targetProductType,
                                platformType: platformType,
                                osDeploymentTarget: osDeploymentTarget,
                                buildFilePath: buildFilePath,
                                objcDefines: objcDefines,
                                swiftDefines: swiftDefines,
                                includePaths: includePaths,
                                swiftLanguageVersion: swiftLanguageVersion,
                                swiftToolchain: swiftToolchain,
                                swiftTransitiveModules: swiftTransitiveModules,
                                objCModuleMaps: objCModuleMaps,
                                moduleName: moduleName,
                                extensionType: extensionType,
                                xcodeVersion: xcodeVersion)
      return ruleEntry
    }


    let bundle = Bundle.main

    let localizedMessageLogger = LocalizedMessageLogger(bundle: bundle)
    let ruleEntryMap = RuleEntryMap(localizedMessageLogger: localizedMessageLogger)
    let semaphore = DispatchSemaphore(value: 1)
     
    // TODO: move this to parallelMap
    let queue = DispatchQueue(label: "com.google.Tulsi.ruleEntryArtifactExtractor",
                                      attributes: DispatchQueue.Attributes.concurrent)
    var hasErrors = false

    for filename in files {
      queue.async {
        let errorInfo: String
        do {
          let ruleEntry = try parseTulsiTargetFile(filename)
          _ = semaphore.wait(timeout: DispatchTime.distantFuture)
          ruleEntryMap.insert(ruleEntry: ruleEntry)
          semaphore.signal()
          return
        } catch ExtractorError.parsingFailed(let info) {
          errorInfo = info
        } catch let e as NSError {
          errorInfo = e.localizedDescription
        } catch {
          errorInfo = "Unexpected exception"
        }
        fatalError("Cannot parse aspects")
        hasErrors = true
      }
    }

    // Wait for everything to be processed.
    queue.sync(flags: .barrier, execute: {})

    if hasErrors {
      fatalError("XCHammer Aspect Parsing failed")
    }
    return ruleEntryMap
  }
}
