XcodeProjectTargetInfo = provider(
fields = {"target_config_json_str":"""
JSON string of target_config
Note: this must be a string as it's a rule input
"""})

def _declare_target_config_impl(ctx):
  return struct(
     providers=[XcodeProjectTargetInfo(target_config_json_str=ctx.attr.json)],
     objc=apple_common.new_objc_provider(),
  )

_declare_target_config = rule(
    implementation=_declare_target_config_impl,
    output_to_genfiles=True,
    attrs = {
        "json": attr.string(mandatory=True),
    },
)

def declare_target_config(name, config):
    """ Declare a target configuration for an Xcode project
    This rule takes a `target_config` from XCHammerConfig
    and aggregates it onto the depgraph
    """
    _declare_target_config(name=name, json=config.to_json())

XcodeConfigurationAspectInfo = provider(
fields = {"value":"""This is the value of the JSON
"""})

def _target_config_aspect_impl(itarget, ctx):
    infos = []
    if XcodeProjectTargetInfo in itarget:
        target = itarget
        json = struct(label=str(itarget.label), value=target[XcodeProjectTargetInfo].target_config_json_str)
        infos.extend([XcodeConfigurationAspectInfo(value=json)])

    # Assumptions:
    # A target has a dep of a single XcodeProjectTargetInfo
    if hasattr(ctx.rule.attr, "deps"):
        for target in ctx.rule.attr.deps:
            if XcodeConfigurationAspectInfo in target:
                infos.append(XcodeConfigurationAspectInfo(value=target[XcodeConfigurationAspectInfo].value))

            if XcodeProjectTargetInfo in target:
                json = struct(label=str(itarget.label), value=target[XcodeProjectTargetInfo].target_config_json_str)
                infos.extend([XcodeConfigurationAspectInfo(value=json)])

    return infos

target_config_aspect = aspect(
    implementation = _target_config_aspect_impl,
    attr_aspects = ["deps"],
)

