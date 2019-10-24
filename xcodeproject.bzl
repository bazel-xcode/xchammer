# Load the sources aspect from Tulsi
load("@tulsi//:tulsi/tulsi_aspects.bzl", "tulsi_sources_aspect", "TulsiSourcesAspectInfo")

# Generally, pass this into Bazel first e.g.
# '--override_repository=tulsi=$HOME/Library/Application Support/xchammer/1.0/Bazel'

def _impl(ctx):
    artifacts = []
    for dep in ctx.attr.targets:
        for a in dep[OutputGroupInfo].tulsi_info.to_list():
            artifacts.append(a)

    xchammer_info_json = ctx.actions.declare_file("xchammer_info.json")    
    xchammer_info=struct(
        tulsiinfos=[a.path for a in artifacts],
        # TODO(V2): This is consumed by bazel_build_settings.py
        # Perhaps that can be replaced out of process or refactored
        execRoot="$(BAZEL_EXEC_ROOT)"
    )
    ctx.file_action(
        content=xchammer_info.to_json(),
        output=xchammer_info_json
    )

    xchammer_command = [
        # TODO: Determine how XCHammer binary is actually compiled and passed in here.
        "/Users/jerrymarino/Projects/xchammer-github/xchammer.app/contents/macos/xchammer",

        "generate_v2",

        ctx.attr.config.files.to_list()[0].path,

        # TODO(V2): This need reconsidering for multi project-mode
        # - write all the schemes here
        # - likely a workspace could have targets on projects?
        "--workspace_root",
        ctx.bin_dir.path,

        "--bazel",
        ctx.attr.bazel,

        "--xcode_project_rule_info",
        xchammer_info_json.path
    ]

    ctx.actions.run_shell(
        inputs=artifacts + [xchammer_info_json],
        command=" ".join(xchammer_command),
        outputs=[ctx.outputs.out]
    )

xcode_project = rule(
    implementation = _impl,
    attrs = {
        "targets" : attr.label_list(aspects = [tulsi_sources_aspect]),
        "project_name" : attr.string(default="Project"),
        "bazel" : attr.string(default="Bazel"),

        # TODO(V2): Perhaps we can unify a lot of XCHammer config into Bazel rule attributes?
        # Specifically:
        # - the top level `targets` attribute, duplicated by above
        # `projects` attribute
        "config" : attr.label(mandatory=True, allow_single_file=True),
    },
    outputs={"out": "%{project_name}.xcodeproj"}
)

