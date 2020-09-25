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
    visibility = ["//visibility:public"],
    deps = [":ios-app-main"],
    minimum_os_version = "9.0",
)

swift_library(
    name = "ios-app-main",
    srcs = [
        "AppDelegate.swift",
    ],
    deps = [":tailor"],
)

swift_library(
    name = "tailor",
    srcs = [
        "Tailor.swift",
    ],
    copts = [
        "-swift-version 4.2",
    ],
    # TODO: Add the ability to customize a module name.
    # This works, but not in Xcode!
    module_name = "tailor",
)

# This is basically the same Xcode project as the Xcode project rule
load(
    "@xchammer//:BazelExtensions/xchammerconfig.bzl",
    "project_config",
)

load("@xchammer//:BazelExtensions/xcodeproject.bzl", "xcode_project")

xcode_project(
    name = "XcodeBazel",
    targets = [
	"//:ios-app",
    ],
    bazel = "tools/bazelwrapper",
    xchammer = "tools/xchammer.app",
    project_config = project_config(
	build_bazel_platform_options = {
            "ios_x86_64": ["--config=ios_x86_64"],
            "ios_i386": ["--config=ios_i386"],
            "ios_arm64": ["--config=ios_arm64"],
            "ios_armv7": ["--config=ios_armv7"],
        },
	paths = ["**"],
	generate_xcode_schemes = True,
	generate_transitive_xcode_targets = True,
    ),
)

