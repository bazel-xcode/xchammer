# Load the sources aspect from Tulsi
load("@tulsi//:tulsi/tulsi_aspects.bzl", "tulsi_sources_aspect", "TulsiSourcesAspectInfo")

# Generally, pass this into Bazel first e.g.
# '--override_repository=tulsi=$HOME/Library/Application Support/xchammer/1.0/Bazel'

def _impl(ctx):
    artifacts = []
    for dep in ctx.attr.deps:
        # Debugging
        #print("Dep", dep[TulsiSourcesAspectInfo])
        #print("OutputGroupInfo", dep[OutputGroupInfo])
        #print("Artifacts", dep_artifacts.to_list())
        dep_artifacts = dep[TulsiSourcesAspectInfo].artifacts
        for a in dep[OutputGroupInfo].tulsi_info.to_list():
            artifacts.append(a)

    xchammer_info_json = ctx.actions.declare_file("xchammer_info.json")    
    xchammer_info=struct(
        tulsiinfos=[a.path for a in artifacts],
        # TODO: Determine where this is used and why.
        execRoot="TODO"
    )
    ctx.file_action(
        content=xchammer_info.to_json(),
        output=xchammer_info_json
    )

    xchammer_command = [
        # TODO: Determine how XCHammer binary is actually compiled and passed in here.
        "/Users/jerrymarino/Projects/xchammer-github/xchammer.app/contents/macos/xchammer",

        "generate_v2",

        # TODO: Generate this dynamically from rule parameters
        # we can port bring the DSL in via rule attributes
        "/Users/jerrymarino/Projects/xchammer-github/bazel-genfiles/xchammer_config/XCHammer.json",

        # TODO: This need reconsidering.
        # - write all the schemes here
        # - copy projects to here.
        # Likely a workspace could have deps on projects?!
        "--workspace_root",
        "/Users/jerrymarino/Projects/xchammer-github/",

        "--bazel",
        ctx.attr.bazel,

        "--xcode_project_rule_info",
        xchammer_info_json.path
    ]

    # The xcode project is actually not used right now, we just log the gen command into it
    ctx.actions.run_shell(
        inputs=artifacts + [xchammer_info_json],
        command=" ".join(xchammer_command) + " | tee -a  " + ctx.outputs.out.path,
        outputs=[ctx.outputs.out]
    )

xcode_project = rule(
    implementation = _impl,
    attrs = {
        "deps" : attr.label_list(aspects = [tulsi_sources_aspect]),
        "project_name" : attr.string(default="Project"),
        "bazel" : attr.string(default="Bazel"),
    },
    outputs={"out": "%{project_name}.xcodeproj"}
)

