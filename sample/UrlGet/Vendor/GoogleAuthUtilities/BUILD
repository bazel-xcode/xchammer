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
    name = "GoogleAuthUtilities_hdrs",
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
    "GoogleAuthUtilities",
    "GoogleAuthUtilities_module_map",
    "GoogleAuthUtilities",
    [
        "GoogleAuthUtilities_hdrs",
    ],
)

objc_library(
    name = "GoogleAuthUtilities",
    hdrs = [
        "GoogleAuthUtilities_module_map_module_map_file",
    ] + [
        "GoogleAuthUtilities_hdrs",
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
        "-IVendor/GoogleAuthUtilities/pod_support/Headers/Public/GoogleAuthUtilities/",
    ] + [
        "-fmodule-name=GoogleAuthUtilities_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "GoogleAuthUtilities_module_map",
        "pod_support/Headers/Public/",
    ],
    pch = pch_with_name_hint(
        "GoogleAuthUtilities",
        [
        ],
    ),
    resources = glob(
        [
            "Frameworks/frameworks/GoogleAuthUtilities.framework/Resources/GTMOAuth2ViewTouch.xib",
        ],
        exclude_directories = 1,
    ),
    sdk_frameworks = [
        "Security",
        "SystemConfiguration",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":GoogleAuthUtilities_VendoredFrameworks",
        "//Vendor/GoogleNetworkingUtilities",
        "//Vendor/GoogleSymbolUtilities",
    ],
)

acknowledged_target(
    name = "GoogleAuthUtilities_acknowledgement",
    value = "//Vendor/GoogleAuthUtilities/pod_support_buildable:acknowledgement_fragment",
    deps = [
        "//Vendor/GoogleNetworkingUtilities:GoogleNetworkingUtilities_acknowledgement",
        "//Vendor/GoogleSymbolUtilities:GoogleSymbolUtilities_acknowledgement",
    ],
)

objc_framework(
    name = "GoogleAuthUtilities_VendoredFrameworks",
    framework_imports = glob(
        [
            "Frameworks/frameworks/GoogleAuthUtilities.framework/**",
        ],
        exclude_directories = 1,
    ),
    is_dynamic = 0,
    visibility = [
        "//visibility:public",
    ],
)

acknowledged_target(
    name = "GoogleAuthUtilities_VendoredFrameworks_acknowledgement",
    value = "//Vendor/GoogleAuthUtilities/pod_support_buildable:acknowledgement_fragment",
    deps = [
    ],
)
