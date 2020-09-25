load("@xchammer//:BazelExtensions/xcodeproject.bzl", "xcode_project")

load(
    "@xchammer//:BazelExtensions/xchammerconfig.bzl",
    "project_config",
)

xcode_project(
    name = "XcodeBazel",
    targets = [
        "//ios-app:ios-app",
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
