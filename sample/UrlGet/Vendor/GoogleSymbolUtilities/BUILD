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
    name = "GoogleSymbolUtilities_hdrs",
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
    name = "GoogleSymbolUtilities_includes",
    include = [
        "Vendor/GoogleSymbolUtilities/pod_support/Headers/Public/",
    ],
)

gen_module_map(
    "GoogleSymbolUtilities",
    "GoogleSymbolUtilities_module_map",
    "GoogleSymbolUtilities",
    [
        "GoogleSymbolUtilities_hdrs",
    ],
)

objc_library(
    name = "GoogleSymbolUtilities",
    hdrs = [
        ":GoogleSymbolUtilities_hdrs",
        ":GoogleSymbolUtilities_module_map_module_map_file",
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
        "-IVendor/GoogleSymbolUtilities/pod_support/Headers/Public/GoogleSymbolUtilities/",
    ] + [
        "-fmodule-name=GoogleSymbolUtilities_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "GoogleSymbolUtilities_module_map",
    ],
    pch = pch_with_name_hint(
        "GoogleSymbolUtilities",
        [],
    ),
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":GoogleSymbolUtilities_VendoredFrameworks",
        ":GoogleSymbolUtilities_includes",
    ],
)

acknowledged_target(
    name = "GoogleSymbolUtilities_acknowledgement",
    value = "//Vendor/GoogleSymbolUtilities/pod_support_buildable:acknowledgement_fragment",
    deps = [],
)

apple_static_framework_import(
    name = "GoogleSymbolUtilities_VendoredFrameworks",
    framework_imports = glob(
        [
            "Frameworks/frameworks/GoogleSymbolUtilities.framework/**",
        ],
        exclude_directories = 1,
    ),
    visibility = [
        "//visibility:public",
    ],
)
