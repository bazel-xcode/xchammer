workspace(name = "xchammer")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

git_repository(
    name = "build_bazel_rules_apple",
    remote = "https://github.com/bazelbuild/rules_apple.git",
    commit = "1cdaf74e44c4c969d7ee739b3a0f11b993c49d2a",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

# TODO: align these with rules_ios
git_repository(
    name = "build_bazel_rules_swift",
    remote = "https://github.com/bazelbuild/rules_swift.git",
    commit = "d07d880dcf939e0ad98df4dd723f8516bf8a2867",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

apple_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

http_file(
    name = "xctestrunner",
    executable = 1,
    urls = ["https://github.com/google/xctestrunner/releases/download/0.2.6/ios_test_runner.par"],
)

## SPM Dependencies

load("//third_party:repositories.bzl", "xchammer_dependencies")

xchammer_dependencies()

## Build system
# This needs to be manually imported
# https://github.com/bazelbuild/bazel/issues/1550
git_repository(
    name = "xcbuildkit",
    remote = "https://github.com/jerrymarino/xcbuildkit.git",
    commit = "b619d25f65cf7195c57e2dbc26d488e5606e763a",
)

load("@xcbuildkit//third_party:repositories.bzl", xcbuildkit_dependencies="dependencies")

xcbuildkit_dependencies()

