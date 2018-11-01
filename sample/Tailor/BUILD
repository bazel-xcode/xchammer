load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load('@build_bazel_rules_swift//swift:swift.bzl', 'swift_library')

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
)

swift_library(
    name = "ios-app-main",
    srcs = [
        "AppDelegate.swift",
    ],
    deps = [":tailor"]
)

swift_library(
    name = "tailor",
    srcs = [
        "Tailor.swift",
    ],
    # TODO: Add the ability to customize a module name.
    # This works, but not in Xcode!
    module_name = "tailor"
)
