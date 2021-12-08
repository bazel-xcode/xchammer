workspace(name = "xchammer")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "55f4dc1c9bf21bb87442665f4618cff1f1343537a2bd89252078b987dcd9c382",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/0.20.0/rules_apple.0.20.0.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "cea22c0616d797e494d7844a9b604520c87f53c81de49613a7e679ec5b821620",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/0.14.0/rules_swift.0.14.0.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load(
    "@com_google_protobuf//:protobuf_deps.bzl",
    "protobuf_deps",
)

protobuf_deps()

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
    commit = "b619d25f65cf7195c57e2dbc26d488e5606e763a",
    remote = "https://github.com/jerrymarino/xcbuildkit.git",
)

load("@xcbuildkit//third_party:repositories.bzl", xcbuildkit_dependencies = "dependencies")

xcbuildkit_dependencies()

## Buildifier deps (Bazel file formatting)
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "d1ffd055969c8f8d431e2d439813e42326961d0942bdf734d2c95dc30c369566",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.24.5/rules_go-v0.24.5.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.24.5/rules_go-v0.24.5.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "com_github_bazelbuild_buildtools",
    strip_prefix = "buildtools-4.2.0",
    url = "https://github.com/bazelbuild/buildtools/archive/4.2.0.zip",
)

load("@com_github_bazelbuild_buildtools//buildifier:deps.bzl", "buildifier_dependencies")

buildifier_dependencies()
