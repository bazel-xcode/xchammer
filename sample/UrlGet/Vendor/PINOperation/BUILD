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
    name = "PINOperation_cxx_hdrs",
    srcs = glob(
        [
            "Source/**/*.h",
        ],
        exclude_directories = 1,
    ),
    visibility = [
        "//visibility:public",
    ],
)

filegroup(
    name = "PINOperation_cxx_union_hdrs",
    srcs = [
        "PINOperation_cxx_hdrs",
        "PINOperation_hdrs",
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "PINOperation_cxx_includes",
    include = [
        "Vendor/PINOperation/pod_support/Headers/Public/",
    ],
)

objc_library(
    name = "PINOperation_cxx",
    srcs = glob(
        [
            "Source/**/*.mm",
        ],
        exclude = [
            "Source/**/*.m",
        ],
        exclude_directories = 1,
    ),
    hdrs = [
        ":PINOperation_cxx_union_hdrs",
        ":PINOperation_module_map_module_map_file",
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
    deps = [
        ":PINOperation_cxx_includes",
    ],
)

acknowledged_target(
    name = "PINOperation_cxx_acknowledgement",
    value = "//Vendor/PINOperation/pod_support_buildable:acknowledgement_fragment",
    deps = [],
)

filegroup(
    name = "PINOperation_hdrs",
    srcs = glob(
        [
            "pod_support/Headers/Public/**/*",
        ],
        exclude_directories = 1,
    ) + glob(
        [
            "Source/**/*.h",
        ],
        exclude_directories = 1,
    ) + [
        ":PINOperation_cxx_hdrs",
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "PINOperation_includes",
    include = [
        "Vendor/PINOperation/pod_support/Headers/Public/",
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
        ],
        exclude_directories = 1,
    ),
    hdrs = [
        ":PINOperation_hdrs",
        ":PINOperation_module_map_module_map_file",
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
    deps = [
        ":PINOperation_cxx",
        ":PINOperation_includes",
    ],
)

acknowledged_target(
    name = "PINOperation_acknowledgement",
    value = "//Vendor/PINOperation/pod_support_buildable:acknowledgement_fragment",
    deps = [],
)
