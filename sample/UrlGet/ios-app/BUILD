load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_extension")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_bundle_import", "apple_resource_group")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])

index_store_copts = [
    "-index-store-path",
    "$(GENDIR)/index-store",
]

ios_extension(
    name = "share-extension",
    bundle_id = "Google.UrlGet.ShareExtension",
    families = ["iphone"],
    infoplists = ["ShareExtension/ShareExtension-Info.plist"],
    minimum_os_version = "10.0",
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
    minimum_os_version = "9.3",
    visibility = ["//visibility:public"],
    deps = ["siri-ext-bin"],
)

filegroup(
    name = "AppIntentVocabulary",
    srcs = glob(["SiriExtension/Resources/Localization/*.lproj/AppIntentVocabulary.plist"]),
    visibility = ["//visibility:public"],
)

apple_resource_group(
    name = "StructuredResources",
    structured_resources = glob(["StructuredResources/**"]),
)

apple_bundle_import(
    name = "ImportedResources",
    bundle_imports = glob(["ImportedResources.bundle/**"]),
)

objc_library(
    name = "siri-ext-bin",
    srcs = glob(["SiriExtension/Sources/**/*.m"]),
    hdrs = glob(["SiriExtension/Sources/**/*.h"]),
    data = [
        ":AppIntentVocabulary",
    ],
)

ios_extension(
    name = "strings-extension",
    bundle_id = "Google.UrlGet.StringsExtension",
    families = ["iphone"],
    infoplists = ["StringsExtension/Resources/StringsExtension-Info.plist"],
    minimum_os_version = "9.3",
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
    srcs = glob(["StringsExtension/Sources/**/*.m"]),
    hdrs = glob(["StringsExtension/Sources/**/*.h"]),
    data = [
        ":StringsIntentVocabulary",
    ],
)

ios_application(
    name = "ios-app",
    bundle_id = "Google.UrlGet",
    entitlements = "Example.entitlements",
    extensions = [
        #":share-extension",
        #":siri-extension",
    ],
    families = ["iphone"],
    infoplists = ["UrlGet/UrlGet-Info.plist"],
    minimum_os_version = "9.3",
    visibility = ["//visibility:public"],
    deps = ["ios-app-bin"],
)

objc_library(
    name = "ios-app-bin",
    srcs = [
        "UrlGet/main.m",
        #":GeneratedSource",
    ],
    data = [
        ":ImportedResources",
        ":StructuredResources",
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
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_ui_test")

# Unit Test Target
objc_library(
    name = "TestsLib",
    srcs = glob(["UnitTests/**/*.m"]),
    hdrs = glob(["UnitTests/**/*.h"]),
    copts = index_store_copts,
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

ios_ui_test(
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
    copts = index_store_copts,

    # Not added
    data = [
        "UrlGet/UrlGetViewController.xib",
        ":StructuredResources",
    ],
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
    deps = [
        "//Vendor/GoogleAppIndexing",
        "//Vendor/GoogleAuthUtilities",
        #"//Vendor/PINCache",
        "//Vendor/PINOperation",
        "//ios-app/HeaderLib",
    ],
)
