load('//Vendor/rules_pods/BazelExtensions:extensions.bzl', 'pch_with_name_hint')
load('//Vendor/rules_pods/BazelExtensions:extensions.bzl', 'acknowledged_target')
load('//Vendor/rules_pods/BazelExtensions:extensions.bzl', 'gen_module_map')
# Add a config setting release for compilation mode
# Assume that people are using `opt` for release mode
# see the bazel user manual for more information
# https://bazel.build/versions/master/docs/bazel-user-manual.html
native.config_setting(
  name = "release",
  values = {
    "compilation_mode": "opt"
  }
  )
filegroup(
  name = "GoogleSymbolUtilities_hdrs",
  srcs = glob(
    [
      "pod_support/Headers/Public/**/*"
    ],
    exclude_directories = 1
    ),
  visibility = [
    "//visibility:public"
  ]
  )
gen_module_map(
  "GoogleSymbolUtilities",
  "GoogleSymbolUtilities_module_map",
  "GoogleSymbolUtilities",
  [
    "GoogleSymbolUtilities_hdrs"
  ]
  )
objc_library(
  name = "GoogleSymbolUtilities",
  enable_modules = 1,
  hdrs = [
    "GoogleSymbolUtilities_module_map_module_map_file"
  ] + [
    "GoogleSymbolUtilities_hdrs"
  ],
  pch = pch_with_name_hint(
    "GoogleSymbolUtilities",
    [

    ]
    ),
  includes = [
    "pod_support/Headers/Public/",
    "GoogleSymbolUtilities_module_map"
  ],
  deps = [
    ":GoogleSymbolUtilities_VendoredFrameworks"
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
    "-Wno-error=nonportable-include-path"
  ] + select(
    {
      "//conditions:default": [
        "-DPOD_CONFIGURATION_RELEASE=0"
      ],
      ":release": [
        "-DPOD_CONFIGURATION_RELEASE=1",
        "-DNS_BLOCK_ASSERTIONS=1"
      ]
    }
    ) + [
    "-IVendor/GoogleSymbolUtilities/pod_support/Headers/Public/GoogleSymbolUtilities/"
  ] + [
    "-fmodule-name=GoogleSymbolUtilities_pod_module"
  ],
  visibility = [
    "//visibility:public"
  ]
  )
acknowledged_target(
  name = "GoogleSymbolUtilities_acknowledgement",
  deps = [

  ],
  value = "//Vendor/GoogleSymbolUtilities/pod_support_buildable:acknowledgement_fragment"
  )
objc_framework(
  name = "GoogleSymbolUtilities_VendoredFrameworks",
  framework_imports = glob(
    [
      "Frameworks/frameworks/GoogleSymbolUtilities.framework/**"
    ],
    exclude_directories = 1
    ),
  is_dynamic = 0,
  visibility = [
    "//visibility:public"
  ]
  )
acknowledged_target(
  name = "GoogleSymbolUtilities_VendoredFrameworks_acknowledgement",
  deps = [

  ],
  value = "//Vendor/GoogleSymbolUtilities/pod_support_buildable:acknowledgement_fragment"
  )