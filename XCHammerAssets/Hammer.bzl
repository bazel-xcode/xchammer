load("@build_bazel_rules_apple//apple/bundling:entitlements.bzl",
     entitlements_rule="entitlements")


def _entitlements_writer_impl(ctx):
    out = ctx.new_file(ctx.attr.name + ".entitlements")

    entitlements_file = ctx.attr.entitlements.objc.link_inputs.to_list()[0]

    # Copy over the linker input to a file name that we control
    cmd = ' '.join([
        'cp', entitlements_file.path, out.path, '\n',
    ])

    ctx.action(
        command=cmd,
        mnemonic="EntitlementsWriter",
        inputs=[entitlements_file],
        outputs=[out]
    )

    return struct(
        files=depset([out])
    )


entitlements_writer = rule(
    implementation=_entitlements_writer_impl,
    attrs={
        "entitlements": attr.label(mandatory=True)
    },
    output_to_genfiles=True
)


def export_entitlements(name,
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
        name=name + "_exported",
        entitlements=entitlements,
        platform_type=platform_type,
        provisioning_profile=provisioning_profile,
        bundle_id=bundle_id,
        visibility=["//visibility:public"]
    )

    # Send entitlements to the writer.
    entitlements_writer(
        name=name,
        entitlements=":" + name + "_exported",
        visibility=["//visibility:public"]
    )
