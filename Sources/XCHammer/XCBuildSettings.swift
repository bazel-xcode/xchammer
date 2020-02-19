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
import ProjectSpec

struct XCSettingKey: CodingKey {
    let value: String

    public var stringValue: String {
        return value
    }

    public init?(stringValue: String) {
        value = stringValue
    }

    public var intValue: Int? {
        return nil
    }

    public init?(intValue _: Int) {
        value = ""
    }

    public func vary(on: String) -> XCSettingKey {
        return XCSettingKey(stringValue: value + "[" + on + "]")!
    }
}

enum XCCodingKey: String {
    case ldFlags = "OTHER_LDFLAGS"
}

protocol XCSettingStringEncodeable {
    func XCSettingString() -> String
}

extension XCSettingStringEncodeable {
    func XCSettingString() -> String {
        return ""
    }
}

extension String: XCSettingStringEncodeable {
    func XCSettingString() -> String {
        return self
    }
}

extension Set: XCSettingStringEncodeable {
    func XCSettingString() -> String {
        return (self as! Set<String>).joined(separator: " ")
    }
}

extension Array: XCSettingStringEncodeable {
    func XCSettingString() -> String {
        return (self as! Array<String>).joined(separator: " ")
    }
}

extension OrderedArray: XCSettingStringEncodeable {
    func XCSettingString() -> String {
        return (self as! OrderedArray<String>).joined(separator: " ")
    }
}

struct Setting<T: XCSettingStringEncodeable & Semigroup>: Semigroup {
    let base: T?
    let SDKiPhoneSimulator: T?
    let SDKiPhone: T?

    static func<>(lhs: Setting, rhs: Setting) -> Setting {
        return Setting(
            base: lhs.base <> rhs.base,
            SDKiPhoneSimulator: lhs.SDKiPhoneSimulator <> rhs.SDKiPhoneSimulator,
            SDKiPhone: lhs.SDKiPhone <> rhs.SDKiPhone)
    }

    init(base: T) {
        self.base = base
        SDKiPhoneSimulator = nil
        SDKiPhone = nil
    }

    init(base: T?, SDKiPhoneSimulator: T?, SDKiPhone: T?) {
        self.base = base
        self.SDKiPhoneSimulator = SDKiPhoneSimulator
        self.SDKiPhone = SDKiPhone
    }

    // Take a data container, and write values to it
    func encode(to container: inout KeyedEncodingContainer<XCSettingKey>, forKey strKey: XCCodingKey) {
        let baseKey = XCSettingKey(stringValue: strKey.rawValue)!

        // Try encoding each setting for a key
        if let base = base {
            let c = base.XCSettingString()
            if c != "" {
                try? container.encode(base.XCSettingString(), forKey: baseKey)
            }
        }

        if let SDKiPhoneSimulator = SDKiPhoneSimulator {
            let c = SDKiPhoneSimulator.XCSettingString()
            if c != "" {
                try? container.encode(SDKiPhoneSimulator.XCSettingString(), forKey: baseKey.vary(on: "sdk=iphonesimulator*"))
            }
        }

        if let SDKiPhone = SDKiPhone {
            let c = SDKiPhone.XCSettingString()
            if c.isEmpty == false {
                try? container.encode(c, forKey: baseKey.vary(on: "sdk=iphoneos*"))
            }
        }
    }
}




struct XCBuildSettings: Encodable {
    var cc: First<String>?
    var ld: First<String>?
    var copts: [String] = []
    var productName: First<String>?
    var enableModules: First<String>?
    var headerSearchPaths: OrderedArray<String> = OrderedArray.empty
    var frameworkSearchPaths: OrderedArray<String> = OrderedArray.empty
    var librarySearchPaths: OrderedArray<String> = OrderedArray.empty
    var archs: First<String>?
    var validArchs: First<String>?
    var pch: First<String>?
    var productBundleId: First<String>?
    var debugInformationFormat: First<String>?
    var codeSigningRequired: First<String>?
    var codeSigningAllowed: First<String>? = First("NO")
    var onlyActiveArch: First<String>?
    var enableTestability: First<String>?
    var enableObjcArc: First<String>?
    var iOSDeploymentTarget: First<String>?
    var watchOSDeploymentTarget: First<String>?
    var tvOSDeploymentTarget: First<String>?
    var macOSDeploymentTarget: First<String>?
    var ldFlags: Setting<OrderedArray<String>> = Setting(base: OrderedArray.empty, SDKiPhoneSimulator: OrderedArray.empty, SDKiPhone: OrderedArray.empty)
    var infoPlistFile: First<String>?
    var testHost: First<String>?
    var bundleLoader: First<String>?
    var appIconName: First<String>?
    var enableBitcode: First<String>? = First("NO")
    var codeSigningIdentity: First<String>? = First("")
    var codeSigningStyle: First<String>? = First("manual")
    var mobileProvisionProfileFile: First<String>?
    var codeSignEntitlementsFile: First<String>?
    var moduleMapFile: First<String>?
    var moduleName: First<String>?
    // Disable Xcode derived headermaps, be explicit to avoid divergence
    var useHeaderMap: First<String>? = First("NO")
    var swiftVersion: First<String>?
    var swiftCopts: [String] = []
    var testTargetName: First<String>?
    var pythonPath: First<String>?
    var sdkRoot: First<String>?
    var targetedDeviceFamily: OrderedArray<String> = OrderedArray.empty
    var isBazel: First<String> = First("NO")
    var diagnosticFlags: [String] = []

    enum CodingKeys: String, CodingKey {
        // Add to this list the known XCConfig keys
        case cc = "CC"
        case ld = "LD"
        case copts = "OTHER_CFLAGS"
        case productName = "PRODUCT_NAME"
        case moduleName = "PRODUCT_MODULE_NAME"
        case enableModules = "CLANG_ENABLE_MODULES"
        case headerSearchPaths = "HEADER_SEARCH_PATHS"
        case frameworkSearchPaths = "FRAMEWORK_SEARCH_PATHS"
        case librarySearchPaths = "LIBRARY_SEARCH_PATHS"
        case archs = "ARCHS"
        case validArchs = "VALID_ARCHS"
        case pch = "GCC_PREFIX_HEADER"
        case productBundleId = "PRODUCT_BUNDLE_IDENTIFIER"
        case codeSigningRequired = "CODE_SIGNING_REQUIRED"
        case codeSigningAllowed = "CODE_SIGNING_ALLOWED"
        case debugInformationFormat = "DEBUG_INFORMATION_FORMAT"
        case onlyActiveArch = "ONLY_ACTIVE_ARCH"
        case enableTestability = "ENABLE_TESTABILITY"
        case enableObjcArc = "CLANG_ENABLE_OBJC_ARC"
        case iOSDeploymentTarget = "IPHONEOS_DEPLOYMENT_TARGET"
        case macOSDeploymentTarget = "MACOSX_DEPLOYMENT_TARGET"
        case tvOSDeploymentTarget = "TVOS_DEPLOYMENT_TARGET"
        case watchOSDeploymentTarget = "WATCHOS_DEPLOYMENT_TARGET"
        case infoPlistFile = "INFOPLIST_FILE"
        case testHost = "TEST_HOST"
        case bundleLoader = "BUNDLE_LOADER"
        case appIconName = "ASSETCATALOG_COMPILER_APPICON_NAME"
        case enableBitcode = "ENABLE_BITCODE"
        case codeSigningIdentity = "CODE_SIGN_IDENTITY[sdk=iphoneos*]"
        case codeSigningStyle = "CODE_SIGN_STYLE"
        case moduleMapFile = "MODULEMAP_FILE"
        case testTargetName = "TEST_TARGET_NAME"
        case useHeaderMap = "USE_HEADERMAP"
        case swiftVersion = "SWIFT_VERSION"
        case swiftCopts = "OTHER_SWIFT_FLAGS"

        case pythonPath = "PYTHONPATH"

        // Hammer Rules
        case codeSignEntitlementsFile = "HAMMER_ENTITLEMENTS_FILE"
        case mobileProvisionProfileFile = "HAMMER_PROFILE_FILE"
        case diagnosticFlags = "HAMMER_DIAGNOSTIC_FLAGS"
        case isBazel = "HAMMER_IS_BAZEL"
        case tulsiWR = "TULSI_WR"
        case sdkRoot = "SDKROOT"
        case targetedDeviceFamily = "TARGETED_DEVICE_FAMILY"
        
    }

    func encode(to encoder: Encoder) throws {
        var XCContainer = encoder.container(keyedBy: XCSettingKey.self)
        ldFlags.encode(to: &XCContainer, forKey: XCCodingKey.ldFlags)

        // TODO: port all of these to XCCodingKey
        var container = encoder.container(keyedBy: CodingKeys.self)

        try cc.map { try container.encode($0.v, forKey: .cc) }
        try ld.map { try container.encode($0.v, forKey: .ld) }
        try container.encode(copts.joined(separator: " "), forKey: .copts)
        try container.encode(swiftCopts.joined(separator: " "), forKey: .swiftCopts)

        try container.encode(headerSearchPaths.joined(separator: " "), forKey: .headerSearchPaths)
        try container.encode(frameworkSearchPaths.joined(separator: " "), forKey: .frameworkSearchPaths)
        try container.encode(librarySearchPaths.joined(separator: " "), forKey: .librarySearchPaths)

        try productName.map { try container.encode($0.v, forKey: .productName) }
        try enableModules.map { try container.encode($0.v, forKey: .enableModules) }
        try archs.map { try container.encode($0.v, forKey: .archs) }
        try validArchs.map { try container.encode($0.v, forKey: .validArchs) }
        try pch.map { try container.encode($0.v, forKey: .pch) }
        try debugInformationFormat.map { try container.encode($0.v, forKey: .debugInformationFormat) }
        try productBundleId.map { try container.encode($0.v, forKey: .productBundleId) }
        try codeSigningRequired.map { try container.encode($0.v, forKey: .codeSigningRequired) }
        try codeSigningAllowed.map { try container.encode($0.v, forKey: .codeSigningAllowed) }
        try codeSigningIdentity.map { try container.encode($0.v, forKey: .codeSigningIdentity) }
        try onlyActiveArch.map { try container.encode($0.v, forKey: .onlyActiveArch) }
        try enableTestability.map { try container.encode($0.v, forKey: .enableTestability) }
        try enableObjcArc.map { try container.encode($0.v, forKey: .enableObjcArc) }
        try iOSDeploymentTarget.map { try container.encode($0.v, forKey: .iOSDeploymentTarget) }
        try macOSDeploymentTarget.map { try container.encode($0.v, forKey: .macOSDeploymentTarget) }
        try tvOSDeploymentTarget.map { try container.encode($0.v, forKey: .tvOSDeploymentTarget) }
        try watchOSDeploymentTarget.map { try container.encode($0.v, forKey: .watchOSDeploymentTarget) }
        try infoPlistFile.map { try container.encode($0.v, forKey: .infoPlistFile) }
        try testHost.map { try container.encode($0.v, forKey: .testHost) }
        try bundleLoader.map { try container.encode($0.v, forKey: .bundleLoader) }
        try appIconName.map { try container.encode($0.v, forKey: .appIconName) }
        try enableBitcode.map { try container.encode($0.v, forKey: .enableBitcode) }
        try codeSigningIdentity.map { try container.encode($0.v, forKey: .codeSigningIdentity) }
        try codeSigningStyle.map { try container.encode($0.v, forKey: .codeSigningStyle) }
        try mobileProvisionProfileFile.map { try container.encode($0.v, forKey: .mobileProvisionProfileFile) }
        try codeSignEntitlementsFile.map { try container.encode($0.v, forKey: .codeSignEntitlementsFile) }
        try moduleMapFile.map { try container.encode($0.v, forKey: .moduleMapFile) }
        try moduleName.map { try container.encode($0.v, forKey: .moduleName) }
        try useHeaderMap.map { try container.encode($0.v, forKey: .useHeaderMap) }
        try testTargetName.map { try container.encode($0.v, forKey: .testTargetName) }
        try pythonPath.map { try container.encode($0.v, forKey: .pythonPath) }
        try sdkRoot.map { try container.encode($0.v, forKey: .sdkRoot) }
        try container.encode(targetedDeviceFamily.joined(separator: ","), forKey: .targetedDeviceFamily)
        try swiftVersion.map { try container.encode($0.v, forKey: .swiftVersion) }
        try container.encode(isBazel.v, forKey: .isBazel)

        // XCHammer only supports Xcode projects at the root directory
        try container.encode("$SOURCE_ROOT", forKey: .tulsiWR)
        try container.encode(diagnosticFlags.joined(separator: " "), forKey: .diagnosticFlags)
    }
}

extension XCBuildSettings: Monoid {
    static var empty: XCBuildSettings {
        return XCBuildSettings()
    }

    static func<>(lhs: XCBuildSettings, rhs: XCBuildSettings) -> XCBuildSettings {
        return XCBuildSettings(
            cc: lhs.cc <> rhs.cc,
            ld: lhs.ld <> rhs.ld,
            copts: lhs.copts <> rhs.copts,
            productName: lhs.productName <> rhs.productName,
            enableModules: lhs.enableModules <> rhs.enableModules,
            headerSearchPaths: lhs.headerSearchPaths <> rhs.headerSearchPaths,
            frameworkSearchPaths: lhs.frameworkSearchPaths <> rhs.frameworkSearchPaths,
            librarySearchPaths: lhs.librarySearchPaths <> rhs.librarySearchPaths,
            archs: lhs.archs <> rhs.archs,
            validArchs: lhs.validArchs <> rhs.validArchs,
            pch: lhs.pch <> rhs.pch,
            productBundleId: lhs.productBundleId <> rhs.productBundleId,
            debugInformationFormat: lhs.debugInformationFormat <> rhs.debugInformationFormat,
            codeSigningRequired: lhs.codeSigningRequired <> rhs.codeSigningRequired,
            codeSigningAllowed: lhs.codeSigningAllowed <> rhs.codeSigningAllowed,
            onlyActiveArch: lhs.onlyActiveArch <> rhs.onlyActiveArch,
            enableTestability: lhs.enableTestability <> rhs.enableTestability,
            enableObjcArc: lhs.enableObjcArc <> rhs.enableObjcArc,
            iOSDeploymentTarget: lhs.iOSDeploymentTarget <> rhs.iOSDeploymentTarget,
            watchOSDeploymentTarget: lhs.watchOSDeploymentTarget <> rhs.watchOSDeploymentTarget,
            tvOSDeploymentTarget: lhs.tvOSDeploymentTarget <> rhs.tvOSDeploymentTarget,
            macOSDeploymentTarget: lhs.macOSDeploymentTarget <> rhs.macOSDeploymentTarget,
            ldFlags: lhs.ldFlags <> rhs.ldFlags,
            infoPlistFile: lhs.infoPlistFile <> rhs.infoPlistFile,
            testHost: lhs.testHost <> rhs.testHost,
            bundleLoader: lhs.bundleLoader <> rhs.bundleLoader,
            appIconName: lhs.appIconName <> rhs.appIconName,
            enableBitcode: lhs.enableBitcode <> rhs.enableBitcode,
            codeSigningIdentity: lhs.codeSigningIdentity <> rhs.codeSigningIdentity,
            codeSigningStyle: lhs.codeSigningStyle <> rhs.codeSigningStyle,
            mobileProvisionProfileFile: lhs.mobileProvisionProfileFile <> rhs.mobileProvisionProfileFile,
            codeSignEntitlementsFile: lhs.codeSignEntitlementsFile <> rhs.codeSignEntitlementsFile,
            moduleMapFile: lhs.moduleMapFile <> rhs.moduleMapFile,
            moduleName: lhs.moduleName <> rhs.moduleName,
            useHeaderMap: lhs.useHeaderMap <> rhs.useHeaderMap,
            swiftVersion: lhs.swiftVersion <> rhs.swiftVersion,
            swiftCopts: lhs.swiftCopts <> rhs.swiftCopts,
            testTargetName: lhs.testTargetName <> rhs.testTargetName,
            pythonPath: lhs.pythonPath <> rhs.pythonPath,
            sdkRoot: lhs.sdkRoot <> rhs.sdkRoot,
            targetedDeviceFamily: lhs.targetedDeviceFamily <>
                rhs.targetedDeviceFamily,
            isBazel: lhs.isBazel <> rhs.isBazel,
            diagnosticFlags: lhs.diagnosticFlags <> rhs.diagnosticFlags
        )
    }

    /// We use this to allocate a ProjectSpec.Settings
    /// TODO: Write a method to output that directly
    func getJSON() -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        let value = try? JSONSerialization.jsonObject(with: data ?? Data())
        return value as? [String: Any] ?? [:]
    }
}

/// Mark - XcodeGen support

func makeXcodeGenSettings(from settings: XCBuildSettings) -> ProjectSpec.Settings {
    return Settings(dictionary: settings.getJSON())
}

