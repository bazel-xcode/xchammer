# Experimental XCHammer DSL.

def _gen_dsl_impl(ctx):
    ctx.file_action(
        content=ctx.attr.ast,
        output=ctx.outputs.xchammerconfig
    )


_gen_dsl = rule(
    implementation=_gen_dsl_impl,
    output_to_genfiles=True,
    attrs={
        "ast": attr.string(mandatory=True),
    },
    outputs={"xchammerconfig": "%{name}/XCHammer.json"}
)


def gen_dsl(
        name,
        ast):
    m = ast.to_json()
    _gen_dsl(name=name, ast=m)

def gen_xchammer_config(name, config):
    gen_dsl(name=name, ast=config)


def scheme_action_config(
    command_line_arguments=None,  # [String: Bool]?
    environment_variables=None, # [EnvironmentVariable]
    pre_actions=None,  # [ExecutionAction]?
    post_actions=None  # [ExecutionAction]?
):
    return struct(command_line_arguments=command_line_arguments, environment_variables=environment_variables, pre_actions=pre_actions, post_actions=post_actions)


def execution_action(
    script,  # String
    name=None,  # String
    settings_target=None  # String
):
    return struct(script=script, name=name, settings_target=settings_target)


def environment_variable(
    variable,  # String
    value,  # String
    enabled=None  # Bool
):
    return struct(variable=variable, value=value, enabled=enabled)


def target_config(
    scheme_config, # [String /*SchemeActionType*/ : XCHammerSchemeActionConfig]?
    build_bazel_options=None,  # String?
    # Startup options passed to the Bazel build invocation
    build_bazel_startup_options=None,  # String?
    build_bazel_template=None,  # String?
    xcconfig_overrides=None  # [String: String]?
):
    return struct(scheme_config=scheme_config, build_bazel_options=build_bazel_options, build_bazel_startup_options=build_bazel_startup_options,build_bazel_template=build_bazel_template, xcconfig_overrides=xcconfig_overrides)


def project_config(
    paths,  # [String]?
    build_bazel_platform_options=None,  # [String: [String]]?
    generate_transitive_xcode_targets=None,  # Bool
    generate_xcode_schemes=None,  # Bool
    xcconfig_overrides=None  # : [String: String]?
):
    return struct(paths=paths, build_bazel_platform_options=build_bazel_platform_options, generate_transitive_xcode_targets=generate_transitive_xcode_targets, generate_xcode_schemes=generate_xcode_schemes, xcconfig_overrides=xcconfig_overrides)


def xchammer_config(
    targets,  # [String]
    projects,  # [String: XCHammerProjectConfig]
    target_config=None  # [String: XCHammerTargetConfig]?
):
    return struct(targets=targets, target_config=target_config, projects=projects)
