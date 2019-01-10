# XCHammer instrumentation helpers

A collection of scripts to add the ability to log stats on local build time and
generation events via `statsd`.

Note: this is a work in progress and is highly subject to change.

## Installation

First import the scripts wherever XCHammer is running from ( e.g. the main repo )

Next, instrumentation can be added as a post and pre action:

e.g. Using the `XCHammerConfig` DSL or setting this in  `XCHammerConfig` directly

```

script_base = "$SRCROOT/tools/instrumentation_helpers"

log_build_start_action = execution_action(
    name="Track build start",
    script="{}/statsd_pre_build_action.sh".format(script_base))

log_build_end_action = execution_action(
    name="Report build end",
    script="python {}/statsd_post_build_action.py &".format(script_base)
)

app_scheme_config={
    "Build": scheme_action_config(
        post_actions=[log_build_end_action],
        pre_actions=[log_build_start_action])
}

# Setup an app target config, to use the scheme actions
app_target_config = target_config(
    build_bazel_template="tools/V2XCHammerBuildRunscriptTemplate.sh.tpl",
    build_bazel_options="$(SPAWN_OPTS)",
    build_bazel_startup_options="$(STARTUP_OPTS)",
    scheme_config=app_scheme_config)

xchammer_config = xchammer_config(
    targets=[
        "//Pinterest/iOS/App:PinterestDevelopment",
    ],
    target_config={
        "//Pinterest/iOS/App:PinterestDevelopment": app_target_config,
    }
)

gen_xchammer_config(name="xchammer_config", config=xchammer_config)
```

