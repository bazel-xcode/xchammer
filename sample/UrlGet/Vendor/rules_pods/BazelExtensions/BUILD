# Process bundles created by PodSpecToBUILD
# Move a bundle of the convention in Pods
# PackageName_Bundle_BundleName
# @see process_ipa.py
py_binary(
    name = "ipa_process",
    srcs = ["process_ipa.py"],
    main = "process_ipa.py",
    visibility = ["//visibility:public"],
)

py_binary(
    name = "acknowledgement_merger",
    srcs = ["acknowledgement_merger.py"],
    visibility = ["//visibility:public"],
)

sh_library(
    name = "vendored_srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
