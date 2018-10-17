load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])

ios_application(
    name = "ios-app",
    bundle_id = "com.Frankenstein",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["ios-app-bin"],
)

objc_library(
    name = "ios-app-bin",
    srcs = [
        "main.m",
    ],
    deps = [
        "//Vendor/React:Core",
        "//Vendor/React:CxxBridge",
        "//Vendor/React:DevSupport",
        "//Vendor/React:RCTAnimation",
        "//Vendor/React:RCTImage",
        "//Vendor/React:RCTNetwork",
        "//Vendor/React:RCTText",
        "//Vendor/React:RCTWebSocket",
        "//Vendor/Yoga",
    ],
)
