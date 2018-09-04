load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_extension")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])


ios_extension(
    name = "share-extension",
    deps = ["ios-ext-bin"],
    infoplists = ["ShareExtension/ShareExtension-Info.plist"],
    bundle_id = "Google.UrlGet.ShareExtension",
    families = ["iphone"],
    visibility = ["//visibility:public"],
)

objc_library(
    name = "ios-ext-bin",
    srcs = ["empty-main.m"]
)

ios_application(
    name = "ios-app",
    deps = ["ios-app-bin"],
    extensions = [":share-extension"],
    infoplists = ["UrlGet/UrlGet-Info.plist"],
    visibility = ["//visibility:public"],
    bundle_id = "Google.UrlGet",
    families = ["iphone"],
)

objc_library(
    name = "ios-app-bin",
    srcs = [
        "UrlGet/main.m",
    ],
    deps = [
        ":UrlGetClasses",
    ],
    defines = [
        "EXAMPLE_DEF=1"
    ]
)

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")

# Unit Test Target
objc_library(
    name = "TestsLib",
    hdrs = native.glob(["UnitTests/**/*.h"]),
    srcs = native.glob(["UnitTests/**/*.m"]),
    deps = [
        ":UrlGetClasses",
    ],
    sdk_frameworks = [
        "XCTest",
        "CoreGraphics",
    ],
    visibility = ["//visibility:public"],
)

ios_unit_test(
    name = "UnitTests",
    minimum_os_version = "9.0",
    deps = [":TestsLib"],
    size = "medium",
    visibility = ["//visibility:public"],
)

ios_unit_test(
    name = "UnitTestsWithHost",
    minimum_os_version = "9.0",
    deps = [":TestsLib"],
    size = "medium",
    visibility = ["//visibility:public"],
    test_host = "//ios-app:ios-app"
)

ios_unit_test(
    name = "UITests",
    minimum_os_version = "9.0",
    deps = [":TestsLib"],
    size = "medium",
    visibility = ["//visibility:public"],
    test_host = "//ios-app:ios-app"
)

objc_library(
    name = "UrlGetClasses",
    srcs = glob(["UrlGet/*.m"], exclude= [
        "UrlGet/NoArc.m",
    ]) + [
        "UrlGet/Some.cc",
    ],
    non_arc_srcs = [
        "UrlGet/NoArc.m",
    ],
    hdrs = glob(["UrlGet/*.h", "UrlGet/*.hpp"]),

    # Not added
    xibs = ["UrlGet/UrlGetViewController.xib"],

    deps = [
        "//ios-app/HeaderLib:HeaderLib",
        "//Vendor/GoogleAppIndexing:GoogleAppIndexing",
        "//Vendor/GoogleAuthUtilities:GoogleAuthUtilities",
        "//Vendor/PINOperation:PINOperation",
        "//Vendor/PINCache:PINCache",
        "//Vendor/Stripe:Stripe",
    ],

    # Not added
    sdk_frameworks = ["CoreLocation", "AudioToolbox", "Security", "UIKit", "CoreGraphics", "QuartzCore", "Foundation", "CoreImage"],
)

