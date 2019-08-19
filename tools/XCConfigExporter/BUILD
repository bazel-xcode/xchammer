package(default_visibility = ["//visibility:public"])

licenses(["notice"])

load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_application",
)
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_bundle_import",
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)
load(
    "@build_bazel_rules_apple//apple:versioning.bzl",
    "apple_bundle_version",
)
load(
    "//third_party:repositories.bzl",
    "namespaced_name",
)

apple_bundle_import(
    name = "Fixtures",
    bundle_imports = glob(["Fixtures.bundle/**"]),
)

swift_library(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
    data = [":Fixtures"],
    deps = ["@" + namespaced_name(x) for x in [
        "XcodeCompilationDatabase//:XcodeCompilationDatabaseCore",
        "ShellOut//:ShellOut",
    ]],
    copts = [
        "-swift-version",
        "4.2"
    ],
)

apple_bundle_version(
    name = "XCConfigExporterVersion",
    build_version = "1.0",
)

macos_application(
    name = "xcconfig-exporter",
    bundle_id = "com.pinterest.xchammer",
    infoplists = ["Info.plist"],
    minimum_os_version = "10.14",
    version = ":XCConfigExporterVersion",
    deps = [":Sources"],
)

