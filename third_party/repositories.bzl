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
objc_library(
  name = "{name}Lib",
  srcs = glob([
    {srcs}
  ]),
  hdrs = glob([
    {hdrs}
  ]),
  includes = [
    {includes}
  ]
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

def namespaced_swift_library(name, srcs, deps = None, defines = None, copts=[]):
    deps = [] if deps == None else deps
    defines = [] if defines == None else defines
    return """
swift_library(
    name = "{name}",
    srcs = glob([{srcs}]),
    module_name = "{name}",
    deps = [{deps}],
    defines = [{defines}],
    copts = ["-DSWIFT_PACKAGE", {copts}],
)""".format(**dict(
        name = name,
        srcs = ",\n".join(['"%s"' % x for x in srcs]),
        defines = ",\n".join(['"%s"' % x for x in defines]),
        deps = ",\n".join(['"%s"' % namespaced_dep_name(x) for x in deps]),
        copts = ",\n".join(['"%s"' % x for x in copts]),
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
        commit = "2cd0210f897fe46c6ce42f52ccfa72b3bbb621a0",
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
        name = "XcodeCompilationDatabase",
        remote = "https://github.com/jerrymarino/XcodeCompilationDatabase.git",
        commit = "598725fdcb37138e9b4ec8379653cbb99f2605dd",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "XcodeCompilationDatabaseCore",
                srcs = ["Sources/**/*.swift"],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "JSONUtilities",
        remote = "https://github.com/yonaskolb/JSONUtilities.git",
        commit = "128d2ffc22467f69569ef8ff971683e2393191a0",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "JSONUtilities",
                srcs = ["Sources/**/*.swift"],
                copts = [
                    "-swift-version",
                    "4.2"
                ],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Nimble",
        remote = "https://github.com/Quick/Nimble.git",
        commit = "43304bf2b1579fd555f2fdd51742771c1e4f2b98",
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
        commit = "cd6dfb86f496fcd96ce0bc6da962cd936bf41903",
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
        commit = "9c52c1952e9b2305d4507cf473392ac2d7c9b155",
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
        commit = "2ca499ba456795616fbc471561ff1d963e6ae160",
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
        commit = "d3d54ce662dfee7fef619330b71d251b8d4869f9",
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

    namespaced_new_git_repository(
        name = "SwiftShell",
        remote = "https://github.com/kareman/SwiftShell",
        commit = "beebe43c986d89ea5359ac3adcb42dac94e5e08a",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "SwiftShell",
                srcs = ["Sources/**/*.swift"],
                copts = [
                    "-swift-version",
                    "4.2"
                ],
            ),
        ]),
    )


    namespaced_git_repository(
        name = "Tulsi",
        remote = "https://github.com/pinterest/tulsi.git",
        commit = "dde8fdd59e7eb2128c91d8f971973d7d28f3aca4",
        patch_cmds = [
            """
         sed -i '' 's/\:__subpackages__/visibility\:public/g' src/TulsiGenerator/BUILD
         """,
            """
         sed -i '' 's/RunLoopMode\.defaultRunLoopMode/RunLoop\.Mode\.`default`/g' src/TulsiGenerator/ProcessRunner.swift
         """,
        ],
    )

    # This is a hack for XCHammer development, but is how XCHammer is imported 
    # into a workspace as a binary build
    new_git_repository(
        name = "xchammer_resources",
        remote = "https://github.com/pinterest/tulsi.git",
        commit = "6302ee15a49a93fcaaff75e1fcd235fc87ac2ec8",
        strip_prefix="src/TulsiGenerator/Bazel",
        build_file_content="# "
    )

    namespaced_new_git_repository(
        name = "XcodeGen",
        remote = "https://github.com/yonaskolb/XcodeGen.git",
        commit = "1942ba36c0c603df723f8fe40bece07fcf981ba3",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "XcodeGenKit",
                srcs = ["Sources/XcodeGenKit/**/*.swift"],
                deps = [
                    ":ProjectSpec",
                    "@JSONUtilities//:JSONUtilities",
                    "@PathKit//:PathKit",
                    "@Yams//:Yams",
                    ":Core",
                ],
            ),
            namespaced_swift_library(
                name = "Core",
                srcs = ["Sources/Core/**/*.swift"],
                deps = [
                    "@PathKit//:PathKit",
                    "@Yams//:Yams",
                ],
            ),
            namespaced_swift_library(
                name = "ProjectSpec",
                srcs = ["Sources/ProjectSpec/**/*.swift"],
                deps = [
                    "@JSONUtilities//:JSONUtilities",
                    "@XcodeProj//:XcodeProj",
                    "@Yams//:Yams",
                    ":Core",
                ],
            ),
        ]),
    )
    namespaced_new_git_repository(
        name = "XcodeProj",
        remote = "https://github.com/tuist/xcodeproj.git",
        commit = "0f563e2d7d604499e7b57a28c78ff23d5c545acd",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "XcodeProj",
                srcs = ["Sources/**/*.swift"],
                deps = [
                    "@AEXML//:AEXML",
                    "@PathKit//:PathKit",
                    "@SwiftShell//:SwiftShell",
                ],
                copts = [
                    "-swift-version",
                    "5"
                ],
            ),
        ]),
    )

    namespaced_new_git_repository(
        name = "Yams",
        remote = "https://github.com/jpsim/Yams.git",
        commit = "c947a306d2e80ecb2c0859047b35c73b8e1ca27f",
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
                deps = [":CYaml", ":CYamlLib"],
                defines = ["SWIFT_PACKAGE"],
            ),
        ]),
    )
