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

ios_extension(
    name = "siri-extension",
    deps = ["siri-ext-bin"],
    infoplists = ["SiriExtension/Resources/SiriExtension-Info.plist"],
    bundle_id = "Google.UrlGet.SiriExtension",
    families = ["iphone"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "AppIntentVocabulary",
    srcs = glob(["SiriExtension/Resources/Localization/*.lproj/AppIntentVocabulary.plist"]),
    visibility = ["//visibility:public"]
)

objc_library(
    name = "siri-ext-bin",
    hdrs = native.glob(["SiriExtension/Sources/**/*.h"]),
    srcs = native.glob(["SiriExtension/Sources/**/*.m"]),
    resources = [
        ":AppIntentVocabulary",
    ],
)

ios_extension(
    name = "strings-extension",
    deps = ["strings-ext-bin"],
    infoplists = ["StringsExtension/Resources/StringsExtension-Info.plist"],
    bundle_id = "Google.UrlGet.StringsExtension",
    families = ["iphone"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "StringsIntentVocabulary",
    srcs = glob(["StringsExtension/Resources/Localization/*.lproj/*.strings"]),
    visibility = ["//visibility:public"]
)

objc_library(
    name = "strings-ext-bin",
    hdrs = native.glob(["StringsExtension/Sources/**/*.h"]),
    srcs = native.glob(["StringsExtension/Sources/**/*.m"]),
    resources = [
        ":StringsIntentVocabulary",
    ],
)

ios_application(
    name = "ios-app",
    deps = ["ios-app-bin"],
    extensions = [":share-extension", ":siri-extension", ":strings-extension"],
    infoplists = ["UrlGet/UrlGet-Info.plist"],
    visibility = ["//visibility:public"],
    bundle_id = "Google.UrlGet",
    families = ["iphone"],
)

objc_library(
    name = "ios-app-bin",
    srcs = [
        "UrlGet/main.m",
        ":GeneratedSource"
    ],
    deps = [
        ":UrlGetClasses",
    ],
    defines = [
        "EXAMPLE_DEF=1"
    ]
)

genrule(
    name = "GeneratedSource",
    srcs = [],
    outs = ["Generated.m"],
    cmd = "touch $@",
    # Set this to the xchammer tag so that the source is present for our Xcode
    # builds, during build time. If you don't use Xcode build, this tag doesn't
    # matter. ( See Docs/XCHammerFAQ.md for more info )
    tags=["xchammer"]
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
    sdk_frameworks = ["CoreLocation", "AudioToolbox", "Security", "UIKit", "CoreGraphics", "QuartzCore", "Foundation", "CoreImage", "Intents"],
)
