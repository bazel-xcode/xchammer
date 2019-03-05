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
# https://bazel.build/versions/master/docs/bazel-user-manual.html
native.config_setting(
    name = "release",
    values = {
        "compilation_mode": "opt",
    },
)

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

filegroup(
    name = "iOSSnapshotTestCase_hdrs",
    srcs = glob(
        [
            "pod_support/Headers/Public/**/*",
        ],
        exclude_directories = 1,
    ) + [
    ] + [
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "iOSSnapshotTestCase_includes",
    include = [
        "Vendor/iOSSnapshotTestCase/pod_support/Headers/Public/",
    ],
)

gen_module_map(
    "FBSnapshotTestCase",
    "iOSSnapshotTestCase_module_map",
    "FBSnapshotTestCase",
    [
        "iOSSnapshotTestCase_hdrs",
    ],
)

objc_library(
    name = "iOSSnapshotTestCase",
    hdrs = [
        ":iOSSnapshotTestCase_hdrs",
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
        "-IVendor/iOSSnapshotTestCase/pod_support/Headers/Public/FBSnapshotTestCase/",
    ] + [
        "-fmodule-name=FBSnapshotTestCase_pod_module",
    ],
    enable_modules = 0,
    pch = pch_with_name_hint(
        "iOSSnapshotTestCase",
        [
        ],
    ),
    sdk_frameworks = [
        "XCTest",
        "UIKit",
        "Foundation",
        "QuartzCore",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":SwiftSupport",
    ] + [
        "iOSSnapshotTestCase_includes",
    ],
)

acknowledged_target(
    name = "iOSSnapshotTestCase_acknowledgement",
    value = "//Vendor/iOSSnapshotTestCase/pod_support_buildable:acknowledgement_fragment",
    deps = [
    ],
)

filegroup(
    name = "Core_hdrs",
    srcs = glob(
        [
            "FBSnapshotTestCase/**/*.h",
            "FBSnapshotTestCase/*.h",
            "FBSnapshotTestCase/Categories/UIImage+Compare.h",
            "FBSnapshotTestCase/Categories/UIImage+Diff.h",
            "FBSnapshotTestCase/Categories/UIImage+Snapshot.h",
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
        "iOSSnapshotTestCase_hdrs",
    ],
    visibility = [
        "//visibility:public",
    ],
)

gen_includes(
    name = "Core_includes",
    include = [
        "Vendor/iOSSnapshotTestCase/pod_support/Headers/Public/",
    ],
)

objc_library(
    name = "Core",
    srcs = glob(
        [
            "FBSnapshotTestCase/**/*.m",
            "FBSnapshotTestCase/*.m",
        ],
        exclude_directories = 1,
    ),
    hdrs = [
        ":Core_union_hdrs",
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
        "-IVendor/iOSSnapshotTestCase/pod_support/Headers/Public/FBSnapshotTestCase/",
    ] + [
        "-fmodule-name=FBSnapshotTestCase_pod_module",
    ],
    enable_modules = 0,
    pch = pch_with_name_hint(
        "iOSSnapshotTestCase",
        [
            "FBSnapshotTestCase/**/*.pch",
        ],
    ),
    sdk_frameworks = [
        "XCTest",
        "UIKit",
        "Foundation",
        "QuartzCore",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
    ] + [
        "Core_includes",
    ],
)

acknowledged_target(
    name = "Core_acknowledgement",
    value = "//Vendor/iOSSnapshotTestCase/pod_support_buildable:acknowledgement_fragment",
    deps = [
    ],
)

swift_library(
    name = "SwiftSupport",
    srcs = glob(
        [
            "FBSnapshotTestCase/**/*.swift",
        ],
        exclude_directories = 1,
    ),
    resources = [
    ],
    deps = [
        ":Core",
    ],
)
