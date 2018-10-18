def _impl(ctx):
    ctx.file("some.h", "extern int SomeVersion;")
    ctx.file("some.m", "int SomeVersion = 1;")
    ctx.file("BUILD", """
objc_library(
    name = "Some",
    srcs = ["some.m"],
    hdrs = ["some.h"],
    visibility = ["//visibility:public"]
)
             """)

gen_repo = repository_rule(
    implementation=_impl,
    local=False,
)
