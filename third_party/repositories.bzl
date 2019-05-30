load(
    "@bazel_tools//tools/build_defs/repo:git.bzl",
    "git_repository",
    "new_git_repository",
)

NAMESPACE_PREFIX = "xchammer-"

def namespaced_name(name):
    if name.startswith("@"):
        return name.replace("@", "@%s" % NAMESPACE_PREFIX)
    return NAMESPACE_PREFIX + name

def namespaced_dep_name(name):
    if name.startswith("@"):
        return name.replace("@", "@%s" % NAMESPACE_PREFIX)
    return name

def namespaced_new_git_repository(name, **kwargs):
    new_git_repository(
        name = namespaced_name(name),
        **kwargs
    )

def namespaced_git_repository(name, **kwargs):
    git_repository(
        name = namespaced_name(name),
        **kwargs
    )

def namespaced_build_file(libs):
    return """
package(default_visibility = ["//visibility:public"])
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_c_module",
"swift_library")
""" + "\n\n".join(libs)

def namespaced_swift_c_library(name, srcs, hdrs, includes, module_map):
    return """
cc_library(
  name = "{name}Lib",
  srcs = glob([
    {srcs}
  ]),
  hdrs = glob([
    {hdrs}
  ]),
  includes = [
    {includes}
  ],
  linkstatic = True
)

swift_c_module(
  name = "{name}",
  deps = [":{name}Lib"],
  module_map = "{module_map}",
)
""".format(**dict(
        name = name,
        srcs = ",\n".join(['"%s"' % x for x in srcs]),
        hdrs = ",\n".join(['"%s"' % x for x in hdrs]),
        includes = ",\n".join(['"%s"' % x for x in includes]),
        module_map = module_map,
    ))

def namespaced_swift_library(name, srcs, deps = None, cc_libs = None, defines = None):
    deps = [] if deps == None else deps
    cc_libs = [] if cc_libs == None else cc_libs
    defines = [] if defines == None else defines
    return """
swift_library(
    name = "{name}",
    srcs = glob([{srcs}]),
    module_name = "{name}",
    deps = [{deps}],
    defines = [{defines}],
    cc_libs = [{cc_libs}]
)""".format(**dict(
        name = name,
        srcs = ",\n".join(['"%s"' % x for x in srcs]),
        defines = ",\n".join(['"%s"' % x for x in defines]),
        deps = ",\n".join(['"%s"' % namespaced_dep_name(x) for x in deps]),
        cc_libs = ",\n".join(['"%s"' % namespaced_dep_name(x) for x in cc_libs]),
    ))

def xchammer_dependencies():
    """Fetches repositories that are dependencies of the xchammer workspace.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of xchammer are downloaded and that they are isolated from
    changes to those dependencies.
    """
    namespaced_new_git_repository(
        name = "AEXML",
        remote = "https://github.com/tadija/AEXML.git",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "AEXML",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
        commit = "54bb8ea6fb693dd3f92a89e5fcc19e199fdeedd0",
    )

    namespaced_new_git_repository(
        name = "Commandant",
        remote = "https://github.com/Carthage/Commandant.git",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Commandant",
                srcs = ["Sources/**/*.swift"],
                deps = [
                    "@Result//:Result",
                ],
            ),
        ]),
        commit = "07cad52573bad19d95844035bf0b25acddf6b0f6",
    )

    namespaced_new_git_repository(
        name = "Commander",
        remote = "https://github.com/kylef/Commander.git",
        commit = "e5b50ad7b2e91eeb828393e89b03577b16be7db9",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Commander",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "JSONUtilities",
        remote = "https://github.com/yonaskolb/JSONUtilities.git",
        commit = "d9f957b1b2a078c93f96c723040d4cbffcb7d3f9",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "JSONUtilities",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Nimble",
        remote = "https://github.com/Quick/Nimble.git",
        commit = "cd6dfb86f496fcd96ce0bc6da962cd936bf41903",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Nimble",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "PathKit",
        remote = "https://github.com/kylef/PathKit.git",
        commit = "e2f5be30e4c8f531c9c1e8765aa7b71c0a45d7a0",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "PathKit",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Quick",
        remote = "https://github.com/Quick/Quick.git",
        commit = "5fbf13871d185526993130c3a1fad0b70bfe37ce",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Quick",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Rainbow",
        remote = "https://github.com/onevcat/Rainbow.git",
        commit = "797a68d0a642609424b08f11eb56974a54d5f6e2",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Rainbow",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Result",
        remote = "https://github.com/antitypical/Result.git",
        commit = "8fc088dcf72802801efeecba76ea8fb041fb773d",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Result",
                srcs = ["Result/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "ShellOut",
        remote = "https://github.com/JohnSundell/ShellOut.git",
        commit = "f1c253a34a40df4bfd268b09fdb101b059f6d52d",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "ShellOut",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Spectre",
        remote = "https://github.com/kylef/Spectre.git",
        commit = "f14ff47f45642aa5703900980b014c2e9394b6e5",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "Spectre",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_git_repository(
        name = "Tulsi",
        remote = "https://github.com/pinterest/Tulsi.git",
        commit = "1dd551137cdb70ce3645d1cc5293be3b981d50bb",
        patch_cmds = [
            """
         sed -i '' 's/\:__subpackages__/visibility\:public/g' src/TulsiGenerator/BUILD
         """,
            """
         sed -i '' 's/RunLoopMode\.defaultRunLoopMode/RunLoop\.Mode\.`default`/g' src/TulsiGenerator/ProcessRunner.swift
         """,
        ],
    )

    namespaced_new_git_repository(
        name = "XcodeGen",
        remote = "https://github.com/yonaskolb/XcodeGen.git",
        commit = "8fcd90367962a9a5c98fcfd3e9981f6a50b1a3e0",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "XcodeGenKit",
                srcs = ["Sources/XcodeGenKit/**/*.swift"],
                deps = [
                    ":ProjectSpec",
                    "@JSONUtilities//:JSONUtilities",
                    "@PathKit//:PathKit",
                    "@Yams//:Yams",
                ],
            ),
            namespaced_swift_library(
                name = "ProjectSpec",
                srcs = ["Sources/ProjectSpec/**/*.swift"],
                deps = [
                    "@JSONUtilities//:JSONUtilities",
                    "@xcproj//:xcproj",
                    "@Yams//:Yams",
                ],
            ),
        ]),
    )
    namespaced_new_git_repository(
        name = "xcproj",
        remote = "https://github.com/tuist/xcodeproj.git",
        commit = "5253c22f208558264e3a64a3a29f11537ca1b41a",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "xcproj",
                srcs = ["Sources/**/*.swift"],
                deps = [
                    "@AEXML//:AEXML",
                    "@PathKit//:PathKit",
                ],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Yams",
        remote = "https://github.com/jpsim/Yams.git",
        commit = "26ab35f50ea891e8edefcc9d975db2f6b67e1d68",
        patch_cmds = [
            """
echo '
module CYaml {
    umbrella header "CYaml.h"
    export *
}
' > Sources/CYaml/include/Yams.modulemap
""",
        ],
        build_file_content = namespaced_build_file([
            namespaced_swift_c_library(
                name = "CYaml",
                srcs = [
                    "Sources/CYaml/src/*.c",
                    "Sources/CYaml/src/*.h",
                ],
                hdrs = [
                    "Sources/CYaml/include/*.h",
                ],
                includes = ["Sources/CYaml/include"],
                module_map = "Sources/CYaml/include/Yams.modulemap",
            ),
            namespaced_swift_library(
                name = "Yams",
                srcs = ["Sources/Yams/*.swift"],
                deps = [":CYaml"],
                cc_libs = [":CYamlLib"],
                defines = ["SWIFT_PACKAGE"],
            ),
        ]),
    )
