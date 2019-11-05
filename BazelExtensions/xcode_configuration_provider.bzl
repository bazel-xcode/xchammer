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

def _extract_generated_sources(target):
    """ Collects all of the generated source files"""
    if not hasattr(target, "objc"):
        return []
    objc_provider = target.objc
    if hasattr(objc_provider, "source") and hasattr(objc_provider, "header"):
        all_files = depset(transitive = [objc_provider.source, objc_provider.header])
        return [f for f in all_files.to_list()  if not f.is_source]
    return []


def _xcode_build_sources_aspect_impl(itarget, ctx):
    infos = []
    if XcodeBuildSourceInfo in itarget:
        target = itarget
        infos.append(itarget.label)

    trans = _extract_generated_sources(itarget)
    infos.extend(trans)

    if hasattr(ctx.rule.attr, "deps"):
        for target in ctx.rule.attr.deps:
            if XcodeBuildSourceInfo in target:
                trans = _extract_generated_sources(target)
                infos.extend(trans)
    return XcodeBuildSourceInfo(values=infos)


xcode_build_sources_aspect = aspect(
    implementation=_xcode_build_sources_aspect_impl, attr_aspects=["*"]
)

