load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_file(
    name = "xctestrunner",
    executable = 1,
    urls = ["https://github.com/jerrymarino/xctestrunner/files/3453677/ios_test_runner.par.zip"],
    sha256 = "4e19d47ffe0c248e1cd91cc647557efdf88a7b0e68dba674222c0745e0c0a47b",
)


http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "2eb3c54fcbcd366d6cb27ce4b0e2e1876745266e0d077f39516016105f6652a1",
    strip_prefix = "rules_swift-f51e68960fca1e0e6d594f3d7b519917ec4f988b",
    url = "https://github.com/bazelbuild/rules_swift/archive/f51e68960fca1e0e6d594f3d7b519917ec4f988b.tar.gz",
)

http_archive(
    name = "build_bazel_apple_support",
    sha256 = "bdbc3f426be3d0fa6489a3b5cb6b7c1af689215a19bfa1abbaaf3cb3280ed58b",
    strip_prefix = "apple_support-9605c3da1c5bcdddc20d1704b52415a6f3a5f422",
    url = "https://github.com/bazelbuild/apple_support/archive/9605c3da1c5bcdddc20d1704b52415a6f3a5f422.tar.gz",
)

git_repository(
    name = "build_bazel_rules_apple",
    remote = "https://github.com/bazelbuild/rules_apple.git",
    commit = "f6a95e8d0c2bd6fa9f0a6280ef3c4d34c9594513",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)
load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

apple_rules_dependencies(ignore_version_differences = True)

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

## SPM Dependencies

load("//third_party:repositories.bzl", "xchammer_dependencies")

xchammer_dependencies()

## Build system
# This needs to be manually imported
# https://github.com/bazelbuild/bazel/issues/1550
git_repository(
    name = "xcbuildkit",
    remote = "https://github.com/jerrymarino/xcbuildkit.git",
    commit = "e32a0cf542421f9051f80cded1a9783a6720e058",
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

# For a binary check-in, this should be declared as so
#local_repository(
#    name="xchammer_resources",
#    path="xchammer.app/Contents/Resources/",
#)

