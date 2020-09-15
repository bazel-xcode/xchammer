# Load the sources aspect from Tulsi
load(
    "@xchammer_resources//:tulsi/tulsi_aspects.bzl",
    "tulsi_sources_aspect",
    "TulsiSourcesAspectInfo",
)
load(":xchammerconfig.bzl", "xchammer_config", "gen_xchammer_config", "project_config")

load(
    ":xcode_configuration_provider.bzl",
    "XcodeProjectTargetInfo",
    "XcodeConfigurationAspectInfo",
    "target_config_aspect",
    "xcode_build_sources_aspect",
    "XcodeBuildSourceInfo",
)

non_hermetic_execution_requirements = { "no-cache": "1", "no-remote": "1", "local": "1", "no-sandbox": "1" }

# Why are we rendering JSON here?
# - the XCHammerConfig is modeled as structs which are passed to rules as strings
# - calling to_json() recursivly renders a dict as a string
# To fix this, we could _try_ to refactor xchammerconfig.bzl and express the
# entire DSL as providers.
def _dict_to_json(value):
    entries = []
    for key in value:
        entries.append("\"" + key + "\":" + value[key] + "")
    return "{ " + ",".join([t for t in entries]) + " }"

def _array_to_json(value):
    return "[ " + ",".join(["\"" + t + "\""  for t in value]) + " ]"

def _xcode_project_impl(ctx):
    # Collect Target configuration JSON from deps
    # Then, merge them to a list
    aggregate_target_config = {}
    for dep in ctx.attr.targets:
        if XcodeConfigurationAspectInfo in dep:
            for info in dep[XcodeConfigurationAspectInfo].values:
                # For some targets, this is set on an internal target. We need
                # to set this on the actual label. The convention is to name the
                # target as ".__internal__.apple_binary" or
                # ".__internal__.SOME"
                if ".__internal__" in info:
                    key = info.split(".__internal__")[0]
                else:
                    key = info
                aggregate_target_config[key] = dep[XcodeConfigurationAspectInfo].values[info]

    xchammerconfig_json = ctx.actions.declare_file(ctx.attr.name + "_xchammer_config.json")
    target_config_attr = ctx.attr.target_config if ctx.attr.target_config else None

    # Consider adding the ability to support this
    if len(aggregate_target_config) > 0 and ctx.attr.target_config:
        print("warning: cannot use aggregate target config and target config directly")
        target_config_json =  _dict_to_json(aggregate_target_config)
    elif len(aggregate_target_config) > 0:
        target_config_json =  _dict_to_json(aggregate_target_config)
    else:
        target_config_json = ctx.attr.target_config
    projects_json = (
        ctx.attr.project_config
        if ctx.attr.project_config
        else project_config(paths=["**"]).to_json()
    )
    xchammerconfig = _dict_to_json({
        "targetConfig" : target_config_json,
        "projects" : _dict_to_json({ctx.attr.project_name: projects_json}),
        "targets": _array_to_json([str(t.label) for t in ctx.attr.targets])
    })
    ctx.actions.write(content=xchammerconfig, output=xchammerconfig_json)

    artifacts = []

    for dep in ctx.attr.targets:
        for a in dep[OutputGroupInfo].tulsi_info.to_list():
            artifacts.append(a)

    xchammer_info_json = ctx.actions.declare_file(ctx.attr.name + "_xchammer_info.json")
    xchammer_info = struct(
        tulsiinfos=[a.path for a in artifacts],
        # This is used by bazel_build_settings.py and replaced by
        # install_xcode_project.
        execRoot="__BAZEL_EXEC_ROOT__",
        # This rule is for the actual _imp. We want XCHammer to run the install
        # target.
        # TODO(V2): for workspace mode, we need a way to invoke this to include all
        # targets
        bazelTargets=[str(ctx.label)[:-5]],
        xchammerPath=ctx.attr.xchammer
        if ctx.attr.xchammer[0] == "/"
        else "$SRCROOT/" + ctx.attr.xchammer,
    )
    ctx.actions.write(content=xchammer_info.to_json(), output=xchammer_info_json)

    # If we're doing a source build of XCHammer then do so
    # this is intended for development of XCHammer only
    xchammer_command = ["set -e;"]
    if ctx.attr.xchammer_bazel_build_target:
        xchammer_files = ctx.attr.xchammer_bazel_build_target.files.to_list()
        xchammer_zip = xchammer_files[0].path
        xchammer_command.append(
            "unzip -o " + xchammer_zip + " -d $(dirname $(readlink $PWD/WORKSPACE))/;"
        )
    else:
        xchammer_files = []

    # TODO(V2): handle absolute paths here
    xchammer_command.append(ctx.attr.xchammer + "/Contents/MacOS/xchammer")

    project_name = ctx.attr.project_name + ".xcodeproj"
    xchammer_command.extend(
        [
            "generate_v2",
            xchammerconfig_json.path,
            # Write the xcode project into the execroot. We need to copy to the
            # bin-dir after generation for validation. This is not 100% safe
            # and needs patches in XcodeGen validation ( or remove XcodeGen )
            # In order to keep this hermetic, the project is installed out of band
            # in another non-hermetic rule which depends on this
            "--workspace_root",
            "$PWD",
            "--bazel",
            ctx.attr.bazel
            if ctx.attr.bazel[0] == "/"
            else "\$SRCROOT/" + ctx.attr.bazel,
            "--xcode_project_rule_info",
            xchammer_info_json.path,
            "; ditto " + project_name + " " + ctx.outputs.out.path,
        ]
    )

    ctx.actions.run_shell(
        mnemonic="XcodeProject",
        inputs=artifacts + [xchammerconfig_json, xchammer_info_json] + xchammer_files,
        command=" ".join(xchammer_command),
        outputs=[ctx.outputs.out],
    )


_xcode_project = rule(
    implementation=_xcode_project_impl,
    attrs={
        "targets": attr.label_list(
            aspects=[tulsi_sources_aspect, target_config_aspect]
        ),
        "project_name": attr.string(),
        "bazel": attr.string(default="bazel"),
        "target_config": attr.string(default="{}"),
        "project_config": attr.string(),
        "xchammer": attr.string(mandatory=True),
        # This is used as a development option only
        "xchammer_bazel_build_target": attr.label(mandatory=False),
    },
    outputs={"out": "%{project_name}.xcodeproj"},
)

# Get the workspace by reading DO_NOT_BUILD_HERE
# https://github.com/bazelbuild/bazel/blob/master/src/main/java/com/google/devtools/build/lib/runtime/BlazeWorkspace.java#L298
get_srcroot = "\"$(cat ../../DO_NOT_BUILD_HERE)/\""

def _install_xcode_project_impl(ctx):
    xcodeproj = ctx.attr.xcodeproj.files.to_list()[0]
    output_proj = "$SRCROOT/" + xcodeproj.basename
    command = [
        "SRCROOT=" + get_srcroot,
        "ditto " + xcodeproj.path + " " + output_proj,
        "sed -i '' \"s,__BAZEL_EXEC_ROOT__,$PWD,g\" "
        + output_proj
        + "/XCHammerAssets/bazel_build_settings.py",
        # This is kind of a hack for reference bazel relative to the source
        # directory, as bazel_build_settings.py doesn't sub Xcode build
        # settings.
        "sed -i '' \"s,\$SRCROOT,$SRCROOT,g\" "
        + output_proj
        + "/XCHammerAssets/bazel_build_settings.py",
        "ln -sf $PWD/external $SRCROOT/external",
        'echo "' + output_proj + '" > ' + ctx.outputs.out.path,
    ]
    ctx.actions.run_shell(
        inputs=ctx.attr.xcodeproj.files,
        command=";".join(command),
        use_default_shell_env=True,
        outputs=[ctx.outputs.out],
        execution_requirements = non_hermetic_execution_requirements
    )


_install_xcode_project = rule(
    implementation=_install_xcode_project_impl,
    attrs={"xcodeproj": attr.label(mandatory=True)},
    outputs={"out": "%{name}.dummy"},
)


def xcode_project(**kwargs):
    """ Generate an Xcode project

    name: attr.string name of the target

    targets:  attr.label_list

    bazel: attr.string path to Bazel used during Xcode builds

    xchammer: attr.string path to xchammer

    project_name: (optional)

    target_config: (optional) struct(target_config)
    
    project_config: (optional) struct(target_config)
    """
    proj_args = kwargs
    rule_name = kwargs["name"]

    if not kwargs.get("project_name"):
        proj_args["project_name"] = kwargs["name"]

    # Build an XCHammer config Based on inputs
    targets_json = [str(t) for t in kwargs.get("targets")]

    # XCHammer development only
    xchammer_target = "//:xchammer"
    if xchammer_target in targets_json:
        proj_args["xchammer_bazel_build_target"] = xchammer_target

    if "target_config" in  proj_args:
        str_dict = {}
        for k in proj_args["target_config"]:
            str_dict[k] = proj_args["target_config"][k].to_json()

        proj_args["target_config"] = _dict_to_json(str_dict)
    else:
        proj_args["target_config"] =  "{}"

    proj_args["name"] = rule_name + "_impl"
    proj_args["project_config"] = proj_args["project_config"].to_json() if "project_config" in  proj_args else None

    _xcode_project(**proj_args)

    # Note: _xcode_project does the hermetic, reproducible bits
    # and then, we install this xcode project into the root directory.
    _install_xcode_project(
        name=rule_name,
        xcodeproj=kwargs["name"],
        testonly=proj_args.get("testonly", False),
    )
