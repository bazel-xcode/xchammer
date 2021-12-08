load("@build_bazel_rules_apple//apple:apple.bzl", "apple_static_framework_import")
load(
    "//Vendor/rules_pods/BazelExtensions:extensions.bzl",
    "acknowledged_target",
    "gen_includes",
    "gen_module_map",
    "pch_with_name_hint",
)

# Add a config setting release for compilation mode
# Assume that people are using `opt` for release mode
# see the bazel user manual for more information
# https://docs.bazel.build/versions/master/be/general.html#config_setting
config_setting(
    name = "release",
    values = {
        "compilation_mode": "opt",
    },
)

filegroup(
    name = "GoogleNetworkingUtilities_hdrs",
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

gen_includes(
    name = "GoogleNetworkingUtilities_includes",
    include = [
        "Vendor/GoogleNetworkingUtilities/pod_support/Headers/Public/",
    ],
)

gen_module_map(
    "GoogleNetworkingUtilities",
    "GoogleNetworkingUtilities_module_map",
    "GoogleNetworkingUtilities",
    [
        "GoogleNetworkingUtilities_hdrs",
    ],
)

objc_library(
    name = "GoogleNetworkingUtilities",
    hdrs = [
        ":GoogleNetworkingUtilities_hdrs",
        ":GoogleNetworkingUtilities_module_map_module_map_file",
    ],
    copts = [
        "-Wno-everything",
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
        "-IVendor/GoogleNetworkingUtilities/pod_support/Headers/Public/GoogleNetworkingUtilities/",
    ] + [
        "-fmodule-name=GoogleNetworkingUtilities_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "GoogleNetworkingUtilities_module_map",
    ],
    pch = pch_with_name_hint(
        "GoogleNetworkingUtilities",
        [],
    ),
    sdk_frameworks = [
        "Security",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":GoogleNetworkingUtilities_VendoredFrameworks",
        ":GoogleNetworkingUtilities_includes",
        "//Vendor/GoogleSymbolUtilities",
    ],
)

acknowledged_target(
    name = "GoogleNetworkingUtilities_acknowledgement",
    value = "//Vendor/GoogleNetworkingUtilities/pod_support_buildable:acknowledgement_fragment",
    deps = [
        "//Vendor/GoogleSymbolUtilities:GoogleSymbolUtilities_acknowledgement",
    ],
)

apple_static_framework_import(
    name = "GoogleNetworkingUtilities_VendoredFrameworks",
    framework_imports = glob(
        [
            "Frameworks/frameworks/GoogleNetworkingUtilities.framework/**",
        ],
        exclude_directories = 1,
    ),
    visibility = [
        "//visibility:public",
    ],
)
