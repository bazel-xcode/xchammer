load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])

ios_application(
    name = "ios-app",
    bundle_id = "com.sample.snapshotme",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    visibility = ["//visibility:public"],
    deps = [":ios-app-main"],
    minimum_os_version = "12.0"
)

objc_library(
    name = "ios-app-main",
    srcs = glob(["*.m"]),
    hdrs = glob(["*.h"]),
    sdk_frameworks = [
        "CoreGraphics",
        "UIKit",  # FIXME: this isn't linking by defaut in the Xcode project ( but it is in Bazel )
    ],
)

ios_unit_test(
    name = "UnitTests",
    size = "medium",
    minimum_os_version = "9.0",
    visibility = ["//visibility:public"],
    deps = [":TestsLib"],
)

objc_library(
    name = "TestsLib",
    srcs = glob(["UnitTests/*.m"]),
    hdrs = glob(["UnitTests/*.h"]),
    sdk_frameworks = [
        "XCTest",
        "CoreGraphics",
        "UIKit",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//Vendor/iOSSnapshotTestCase:Core",
    ],
)
