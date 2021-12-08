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

config_setting(
    name = "iosCase",
    values = {
        "cpu": "powerpc1",
    },
)

config_setting(
    name = "osxCase",
    values = {
        "cpu": "powerpc2",
    },
)

filegroup(
    name = "PINCache_hdrs",
    srcs = glob(
        [
            "pod_support/Headers/Public/**/*",
        ],
        exclude_directories = 1,
    ) + [
        ":Core_hdrs",
        ":Arc-exception-safe_hdrs",
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "PINCache_includes",
    include = [
        "Vendor/PINCache/pod_support/Headers/Public/",
    ],
)

gen_module_map(
    "PINCache",
    "PINCache_module_map",
    "PINCache",
    [
        "PINCache_hdrs",
    ],
)

objc_library(
    name = "PINCache",
    hdrs = [
        ":PINCache_hdrs",
        ":PINCache_module_map_module_map_file",
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
        "-IVendor/PINCache/pod_support/Headers/Public/PINCache/",
    ] + [
        "-fmodule-name=PINCache_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "PINCache_module_map",
    ],
    pch = pch_with_name_hint(
        "PINCache",
        [],
    ),
    sdk_frameworks = [
        "Foundation",
    ],
    visibility = [
        "//visibility:public",
    ],
    weak_sdk_frameworks = select(
        {
            "//conditions:default": [
                "UIKit",
            ],
            ":osxCase": [
                "AppKit",
            ],
        },
    ),
    deps = [
        ":Arc-exception-safe",
        ":Core",
        ":PINCache_includes",
    ],
)

acknowledged_target(
    name = "PINCache_acknowledgement",
    value = "//Vendor/PINCache/pod_support_buildable:acknowledgement_fragment",
    deps = [],
)

filegroup(
    name = "Core_hdrs",
    srcs = glob(
        [
            "Source/*.h",
        ],
        exclude_directories = 1,
    ),
    visibility = [
        "//visibility:public",
    ],
)

filegroup(
    name = "Core_union_hdrs",
    srcs = [
        "Core_hdrs",
        "PINCache_hdrs",
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "Core_includes",
    include = [
        "Vendor/PINCache/pod_support/Headers/Public/",
    ],
)

objc_library(
    name = "Core",
    srcs = glob(
        [
            "Source/*.m",
        ],
        exclude = [
            "Source/PINDiskCache.m",
        ],
        exclude_directories = 1,
    ),
    hdrs = [
        ":Core_union_hdrs",
        ":PINCache_module_map_module_map_file",
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
        "-IVendor/PINCache/pod_support/Headers/Public/PINCache/",
    ] + [
        "-fmodule-name=PINCache_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "PINCache_module_map",
    ],
    pch = pch_with_name_hint(
        "PINCache",
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
    weak_sdk_frameworks = select(
        {
            "//conditions:default": [
                "UIKit",
            ],
            ":osxCase": [
                "AppKit",
            ],
        },
    ),
    deps = [
        ":Core_includes",
        "//Vendor/PINOperation",
    ],
)

acknowledged_target(
    name = "Core_acknowledgement",
    value = "//Vendor/PINCache/pod_support_buildable:acknowledgement_fragment",
    deps = [
        "//Vendor/PINOperation:PINOperation_acknowledgement",
    ],
)

filegroup(
    name = "Arc-exception-safe_hdrs",
    srcs = [],
    visibility = [
        "//visibility:public",
    ],
)

filegroup(
    name = "Arc-exception-safe_union_hdrs",
    srcs = [
        "Arc-exception-safe_hdrs",
        "PINCache_hdrs",
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "Arc-exception-safe_includes",
    include = [
        "Vendor/PINCache/pod_support/Headers/Public/",
    ],
)

objc_library(
    name = "Arc-exception-safe",
    srcs = glob(
        [
            "Source/PINDiskCache.m",
        ],
        exclude_directories = 1,
    ),
    hdrs = [
        ":Arc-exception-safe_union_hdrs",
        ":PINCache_module_map_module_map_file",
    ],
    copts = [
        "-fobjc-arc-exceptions",
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
        "-IVendor/PINCache/pod_support/Headers/Public/PINCache/",
    ] + [
        "-fmodule-name=PINCache_pod_module",
    ],
    enable_modules = 1,
    includes = [
        "PINCache_module_map",
    ],
    pch = pch_with_name_hint(
        "PINCache",
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
    weak_sdk_frameworks = select(
        {
            "//conditions:default": [
                "UIKit",
            ],
            ":osxCase": [
                "AppKit",
            ],
        },
    ),
    deps = [
        ":Arc-exception-safe_includes",
        ":Core",
    ],
)

acknowledged_target(
    name = "Arc-exception-safe_acknowledgement",
    value = "//Vendor/PINCache/pod_support_buildable:acknowledgement_fragment",
    deps = [],
)
