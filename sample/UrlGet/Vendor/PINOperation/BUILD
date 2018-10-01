load("//Vendor/rules_pods/BazelExtensions:extensions.bzl", "pch_with_name_hint")
load("//Vendor/rules_pods/BazelExtensions:extensions.bzl", "acknowledged_target")
load("//Vendor/rules_pods/BazelExtensions:extensions.bzl", "gen_module_map")

# Add a config setting release for compilation mode
# Assume that people are using `opt` for release mode
# see the bazel user manual for more information
# https://bazel.build/versions/master/docs/bazel-user-manual.html
native.config_setting(
    name = "release",
    values = {
        "compilation_mode": "opt",
    },
)

filegroup(
    name = "PINOperation_hdrs",
    srcs = glob(
        [
            "pod_support/Headers/Public/**/*",
        ],
        exclude_directories = 1,
    ),
    visibility = [
        "//visibility:public",
    ],
)

gen_module_map(
    "PINOperation",
    "PINOperation_module_map",
    "PINOperation",
    [
        "PINOperation_hdrs",
    ],
)

objc_library(
    name = "PINOperation",
    srcs = glob(
        [
            "Source/**/*.m",
            "Source/**/*.mm",
        ],
        exclude_directories = 1,
    ) + glob(
        [
            "Source/**/*.h",
        ],
        exclude_directories = 1,
    ) + [
    ],
    hdrs = [
        "PINOperation_module_map_module_map_file",
    ] + [
        "PINOperation_hdrs",
    ],
    copts = [
        "-Wnon-modular-include-in-framework-module",
        "-g",
        "-stdlib=libc++",
        "-DCOCOAPODS=1",
        "-DOBJC_OLD_DISPATCH_PROTOTYPES=0",
        "-fdiagnostics-show-note-include-stack",
        "-fno-common",
        "-fembed-bitcode-marker",
        "-fmessage-length=0",
        "-fpascal-strings",
        "-fstrict-aliasing",
        "-Wno-error=nonportable-include-path",
    ] + select(
        {
            "//conditions:default": [
                "-DPOD_CONFIGURATION_RELEASE=0",
            ],
            ":release": [
                "-DPOD_CONFIGURATION_RELEASE=1",
                "-DNS_BLOCK_ASSERTIONS=1",
            ],
        },
    ) + [
        "-IVendor/PINOperation/pod_support/Headers/Public/PINOperation/",
    ] + [
        "-fmodule-name=PINOperation_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "PINOperation_module_map",
        "pod_support/Headers/Public/",
    ],
    pch = pch_with_name_hint(
        "PINOperation",
        [
            "Source/**/*.pch",
        ],
    ),
    sdk_frameworks = [
        "Foundation",
    ],
    visibility = [
        "//visibility:public",
    ],
)

acknowledged_target(
    name = "PINOperation_acknowledgement",
    value = "//Vendor/PINOperation/pod_support_buildable:acknowledgement_fragment",
    deps = [
    ],
)
