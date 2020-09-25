load(
    "@xchammer//:BazelExtensions/tulsi.bzl",
    "SwiftInfo",
)

XcodeProjectTargetInfo = provider(
    fields={
        "target_config_json_str": """
JSON string of target_config
Note: this must be a string as it's a rule input
"""
    }
)


def _declare_target_config_impl(ctx):
    return struct(
        providers=[XcodeProjectTargetInfo(target_config_json_str=ctx.attr.json)],
        objc=apple_common.new_objc_provider(),
    )


_declare_target_config = rule(
    implementation=_declare_target_config_impl,
    output_to_genfiles=True,
    attrs={"json": attr.string(mandatory=True)},
)


def declare_target_config(name, config, **kwargs):
    """ Declare a target configuration for an Xcode project
    This rule takes a `target_config` from XCHammerConfig
    and aggregates it onto the depgraph
    """
    _declare_target_config(name=name, json=config.to_json().replace("\\", ""), **kwargs)


XcodeConfigurationAspectInfo = provider(
    fields={
        "values": """This is the value of the JSON
"""
    }
)


def _target_config_aspect_impl(itarget, ctx):
    infos = []
    if ctx.rule.kind == "_declare_target_config":
        return []
    info_map = {}
    if XcodeProjectTargetInfo in itarget:
        target = itarget
        info_map[str(itarget.label)] = target[XcodeProjectTargetInfo].target_config_json_str

    if hasattr(ctx.rule.attr, "deps"):
        for target in ctx.rule.attr.deps:
            if XcodeConfigurationAspectInfo in target:
                for info in target[XcodeConfigurationAspectInfo].values:
                    info_map[info] = target[XcodeConfigurationAspectInfo].values[info]

            elif XcodeProjectTargetInfo in target:
                info_map[str(itarget.label)] = target[XcodeProjectTargetInfo].target_config_json_str

    return XcodeConfigurationAspectInfo(values=info_map)


target_config_aspect = aspect(
    implementation=_target_config_aspect_impl, attr_aspects=["*"]
)


XcodeBuildSourceInfo = provider(
    fields={
        "values": """The values of source files
"""
    }
)

def _extract_generated_sources(target, ctx):
    """ Collects all of the generated source files"""

    files = []
    if ctx.rule.kind == "entitlements_writer":
        files.append(target.files)

    if SwiftInfo in target:
        include_swift_outputs = ctx.attr.include_swift_outputs == "true"
        module_info = target[SwiftInfo]
        if hasattr(module_info, "transitive_modulemaps"):
            files.append(module_info.transitive_modulemaps)
        if include_swift_outputs and hasattr(module_info, "transitive_swiftmodules"):
            files.append(module_info.transitive_swiftmodules)

    if hasattr(target, "objc"):
        objc = target.objc
        files.append(objc.source)
        files.append(objc.header)
        files.append(objc.module_map)

    trans_files = depset(transitive = files)
    return [f for f in trans_files.to_list()  if not f.is_source]

get_srcroot = "\"$(cat ../../DO_NOT_BUILD_HERE)/\""
non_hermetic_execution_requirements = { "no-cache": "1", "no-remote": "1", "local": "1", "no-sandbox": "1" }

def _install_action(ctx, infos, itarget):
    inputs = []
    cmd = []
    cmd.append("SRCROOT=" + get_srcroot)
    for info in infos:
        parts = info.path.split("/bin/")
        dirname = info.path
        short_path = info.short_path.split("/")[:-1]
        if len(short_path) > 0 and short_path[0] == "..":
            target_dir = "external/" + "/".join(short_path[1:])
        else:
            target_dir = "/".join(short_path)
        if len(parts) > 0:
            inputs.append(info)
            last = parts[len(parts) - 1]
            cmd.append(
                "target_dir=\"$SRCROOT/xchammer-includes/x/x/" + target_dir + "\""
            )
            cmd.append("mkdir -p \"$target_dir\"")
            cmd.append("ditto " + info.path + " \"$target_dir\"")

    output = ctx.actions.declare_file(itarget.label.name + "_outputs.dummy")
    cmd.append("touch " + output.path)
    ctx.actions.run_shell(
        inputs=inputs,
        command="\n".join(cmd),
        use_default_shell_env=True,
        outputs=[output],
        execution_requirements = non_hermetic_execution_requirements
    )
    return [output]

def _xcode_build_sources_aspect_impl(itarget, ctx):
    """ Install Xcode project dependencies into the source root.
    This is required as by default, Bazel only installs genfiles for those
    genfiles which are passed to the Bazel command line.
    """

    # Note: we need to collect the transitive files seperately from our own
    infos = []
    trans = []
    infos.extend(_extract_generated_sources(itarget, ctx))
    if hasattr(ctx.rule.attr, "deps"):
        for target in ctx.rule.attr.deps:
            if XcodeBuildSourceInfo in target:
                infos.extend(_extract_generated_sources(target, ctx))
                trans.extend(target[XcodeBuildSourceInfo].values)

    return [
        OutputGroupInfo(
            xcode_project_deps = _install_action(
                ctx,
                depset(infos + trans).to_list(),
                itarget,
            ),
        ),
        XcodeBuildSourceInfo(values = infos),
    ]


# Note, that for "pure" Xcode builds we build swiftmodules with Xcode, so we
# don't need to pre-compile them with Bazel
pure_xcode_build_sources_aspect = aspect(
    implementation=_xcode_build_sources_aspect_impl, attr_aspects=["*"],
    attrs = { "include_swift_outputs": attr.string(values=["false","true"], default="false") }
)

xcode_build_sources_aspect = aspect(
    implementation=_xcode_build_sources_aspect_impl, attr_aspects=["*"],
    attrs = { "include_swift_outputs": attr.string(values=["false", "true"], default="true") }
)

