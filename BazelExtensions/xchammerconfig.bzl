# Experimental XCHammer DSL.


def _gen_dsl_impl(ctx):
    ctx.actions.write(
        content = ctx.attr.ast,
        output = ctx.outputs.xchammerconfig,
    )

_gen_dsl = rule(
    implementation = _gen_dsl_impl,
    output_to_genfiles = True,
    attrs = {
        "ast": attr.string(mandatory = True),
    },
    outputs = {"xchammerconfig": "%{name}/XCHammer.json"},
)

def gen_dsl(
        name,
        ast):
    m = ast.to_json()
    _gen_dsl(name = name, ast = m)

def gen_xchammer_config(name, config):
    gen_dsl(name = name, ast = config)

def scheme_action_config(
        command_line_arguments = None,  # [String: Bool]?
        environment_variables = None,  # [EnvironmentVariable]
        pre_actions = None,  # [ExecutionAction]?
        post_actions = None):  # [ExecutionAction]?
    return struct(commandLineArguments = command_line_arguments, environmentVariables = environment_variables, preActions = pre_actions, postActions = post_actions)

def execution_action(
        script,  # String
        name = None,  # String
        settings_target = None):  # String
    return struct(script = script, name = name, settingsTarget = settings_target)

def environment_variable(
        variable,  # String
        value,  # String
        enabled = None):  # Bool
    return struct(variable = variable, value = value, enabled = enabled)

def target_config(
        scheme_config = None,  # [String /*SchemeActionType*/ : XCHammerSchemeActionConfig]?
        build_bazel_options = None,  # String?
        # Startup options passed to the Bazel build invocation
        build_bazel_startup_options = None,  # String?
        build_bazel_template = None,  # String?
        xcconfig_overrides = None):  # [String: String]?
    return struct(schemeConfig = scheme_config, buildBazelOptions = build_bazel_options, buildBazelStartupOptions = build_bazel_startup_options, buildBazelTemplate = build_bazel_template, xcconfigOverrides = xcconfig_overrides)

def project_config(
        paths,  # [String]?
        build_bazel_platform_options = None,  # [String: [String]]?
        generate_transitive_xcode_targets = None,  # Bool
        generate_xcode_schemes = None,  # Bool
        xcconfig_overrides = None):  # : [String: String]?
    return struct(paths = paths, buildBazelPlatformOptions = build_bazel_platform_options, generateTransitiveXcodeTargets = generate_transitive_xcode_targets, generateXcodeSchemes = generate_xcode_schemes, xcconfigOverrides = xcconfig_overrides)

def xchammer_config(
        targets,  # [String]
        projects,  # [String: XCHammerProjectConfig]
        target_config = None):  # [String: XCHammerTargetConfig]?
    return struct(targets = targets, targetConfig = target_config, projects = projects)
