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

apple_rules_dependencies()

load(
    "@com_google_protobuf//:protobuf_deps.bzl",
    "protobuf_deps",
)

protobuf_deps()

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


## Buildifier deps (Bazel file formatting)
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "3743a20704efc319070957c45e24ae4626a05ba4b1d6a8961e87520296f1b676",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.18.4/rules_go-0.18.4.tar.gz",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "com_github_bazelbuild_buildtools",
    strip_prefix = "buildtools-0.25.0",
    url = "https://github.com/bazelbuild/buildtools/archive/0.25.0.zip",
)

load("@com_github_bazelbuild_buildtools//buildifier:deps.bzl", "buildifier_dependencies")

buildifier_dependencies()
