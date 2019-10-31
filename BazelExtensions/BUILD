package(default_visibility = ["//visibility:public"])

load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_resource_group",
)

# This BUILD file is not actually imported into XCHammer
# There is already a BUILD file placed in there by another dep.
apple_resource_group(
    name = "BazelExtensions",
    structured_resources=glob([
        "*.bzl",
    ]),
)


