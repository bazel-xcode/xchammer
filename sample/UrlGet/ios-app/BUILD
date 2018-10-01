load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_extension")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])

ios_extension(
    name = "share-extension",
    bundle_id = "Google.UrlGet.ShareExtension",
    families = ["iphone"],
    infoplists = ["ShareExtension/ShareExtension-Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["ios-ext-bin"],
)

objc_library(
    name = "ios-ext-bin",
    srcs = ["empty-main.m"],
)

ios_extension(
    name = "siri-extension",
    bundle_id = "Google.UrlGet.SiriExtension",
    families = ["iphone"],
    infoplists = ["SiriExtension/Resources/SiriExtension-Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["siri-ext-bin"],
)

filegroup(
    name = "AppIntentVocabulary",
    srcs = glob(["SiriExtension/Resources/Localization/*.lproj/AppIntentVocabulary.plist"]),
    visibility = ["//visibility:public"],
)

objc_library(
    name = "siri-ext-bin",
    srcs = native.glob(["SiriExtension/Sources/**/*.m"]),
    hdrs = native.glob(["SiriExtension/Sources/**/*.h"]),
    resources = [
        ":AppIntentVocabulary",
    ],
)

ios_extension(
    name = "strings-extension",
    bundle_id = "Google.UrlGet.StringsExtension",
    families = ["iphone"],
    infoplists = ["StringsExtension/Resources/StringsExtension-Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["strings-ext-bin"],
)

filegroup(
    name = "StringsIntentVocabulary",
    srcs = glob(["StringsExtension/Resources/Localization/*.lproj/*.strings"]),
    visibility = ["//visibility:public"],
)

objc_library(
    name = "strings-ext-bin",
    srcs = native.glob(["StringsExtension/Sources/**/*.m"]),
    hdrs = native.glob(["StringsExtension/Sources/**/*.h"]),
    resources = [
        ":StringsIntentVocabulary",
    ],
)

ios_application(
    name = "ios-app",
    bundle_id = "Google.UrlGet",
    extensions = [
        ":share-extension",
        ":siri-extension",
        ":strings-extension",
    ],
    families = ["iphone"],
    infoplists = ["UrlGet/UrlGet-Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["ios-app-bin"],
)

objc_library(
    name = "ios-app-bin",
    srcs = [
        "UrlGet/main.m",
        ":GeneratedSource",
    ],
    defines = [
        "EXAMPLE_DEF=1",
    ],
    deps = [
        ":UrlGetClasses",
    ],
)

genrule(
    name = "GeneratedSource",
    srcs = [],
    outs = ["Generated.m"],
    cmd = "touch $@",
    # Set this to the xchammer tag so that the source is present for our Xcode
    # builds, during build time. If you don't use Xcode build, this tag doesn't
    # matter. ( See Docs/XCHammerFAQ.md for more info )
    tags = ["xchammer"],
)

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")

# Unit Test Target
objc_library(
    name = "TestsLib",
    srcs = native.glob(["UnitTests/**/*.m"]),
    hdrs = native.glob(["UnitTests/**/*.h"]),
    sdk_frameworks = [
        "XCTest",
        "CoreGraphics",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":UrlGetClasses",
    ],
)

ios_unit_test(
    name = "UnitTests",
    size = "medium",
    minimum_os_version = "9.0",
    visibility = ["//visibility:public"],
    deps = [":TestsLib"],
)

ios_unit_test(
    name = "UnitTestsWithHost",
    size = "medium",
    minimum_os_version = "9.0",
    test_host = "//ios-app:ios-app",
    visibility = ["//visibility:public"],
    deps = [":TestsLib"],
)

ios_unit_test(
    name = "UITests",
    size = "medium",
    minimum_os_version = "9.0",
    test_host = "//ios-app:ios-app",
    visibility = ["//visibility:public"],
    deps = [":TestsLib"],
)

objc_library(
    name = "UrlGetClasses",
    srcs = glob(
        ["UrlGet/*.m"],
        exclude = [
            "UrlGet/NoArc.m",
        ],
    ) + [
        "UrlGet/Some.cc",
    ],
    hdrs = glob([
        "UrlGet/*.h",
        "UrlGet/*.hpp",
    ]),
    non_arc_srcs = [
        "UrlGet/NoArc.m",
    ],

    # Not added
    sdk_frameworks = [
        "CoreLocation",
        "AudioToolbox",
        "Security",
        "UIKit",
        "CoreGraphics",
        "QuartzCore",
        "Foundation",
        "CoreImage",
        "Intents",
    ],

    # Not added
    xibs = ["UrlGet/UrlGetViewController.xib"],
    deps = [
        "//Vendor/GoogleAppIndexing",
        "//Vendor/GoogleAuthUtilities",
        "//Vendor/PINCache",
        "//Vendor/PINOperation",
        "//Vendor/Stripe",
        "//ios-app/HeaderLib",
    ],
)
