load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])

ios_application(
    name = "ios-app",
    bundle_id = "com.Sample",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "10.0",
    visibility = ["//visibility:public"],
    deps = ["ios-app-main"],
)

objc_library(
    name = "ios-app-main",
    srcs = [
        "main.m",
    ],
    deps = ["@Some"],
)

load(
    "@xchammer//:BazelExtensions/xchammerconfig.bzl",
    "project_config",
)
load("@xchammer//:BazelExtensions/xcodeproject.bzl", "xcode_project")

xcode_project(
    name = "XcodeBazel",
    bazel = "tools/bazelwrapper",
    project_config = project_config(
        build_bazel_platform_options = {
            "ios_x86_64": ["--config=ios_x86_64"],
            "ios_i386": ["--config=ios_i386"],
            "ios_arm64": ["--config=ios_arm64"],
            "ios_armv7": ["--config=ios_armv7"],
        },
        generate_transitive_xcode_targets = True,
        generate_xcode_schemes = True,
        paths = ["**"],
    ),
    targets = [
        "//:ios-app",
    ],
)
