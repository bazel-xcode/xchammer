load(
    "@build_bazel_rules_apple//apple/internal:entitlement_rules.bzl",
    entitlements_rule = "entitlements",
)
load(
    "@build_bazel_rules_apple//apple/internal:entitlement_rules.bzl",
    "AppleEntitlementsInfo",
)

def _entitlements_writer_impl(ctx):
    entitlement_info = ctx.attr.entitlements[AppleEntitlementsInfo]
    out = ctx.actions.declare_file(ctx.attr.name + ".entitlements")
    if not entitlement_info or not entitlement_info.final_entitlements:
        # Create some dummy entitlements
        cmd = " ".join([
            "touch",
            out.path,
            "\n",
        ])

        ctx.actions.run_shell(
            command = cmd,
            mnemonic = "EntitlementsWriter",
            inputs = [],
            outputs = [out],
        )
        return struct(
            files = depset([out]),
        )

    # Export the entitlements from link_inputs
    entitlements_file = entitlement_info.final_entitlements
    cmd = " ".join([
        "cp",
        entitlements_file.path,
        out.path,
        "\n",
    ])

    ctx.actions.run_shell(
        command = cmd,
        mnemonic = "EntitlementsWriter",
        inputs = [entitlements_file],
        outputs = [out],
    )

    return struct(
        files = depset([out]),
    )

entitlements_writer = rule(
    implementation = _entitlements_writer_impl,
    attrs = {
        "entitlements": attr.label(mandatory = True),
    },
    output_to_genfiles = True,
)

def export_entitlements(
        name,
        entitlements,
        provisioning_profile,
        bundle_id,
        platform_type):
    """Macro that configure entitlements for use outside of Bazel.
    - Accept an entitlements rule name.
    - Derive a "name" + "_out" target.

    Finally, it uses `rules_apple` to build up an entitlements file.
    """
    entitlements_rule(
        name = name + "_exported",
        entitlements = entitlements,
        platform_type = platform_type,
        provisioning_profile = provisioning_profile,
        bundle_id = bundle_id,
        visibility = ["//visibility:public"],
    )

    # Send entitlements to the writer.
    entitlements_writer(
        name = name,
        entitlements = ":" + name + "_exported",
        visibility = ["//visibility:public"],
        tags = ["xchammer"],
    )
