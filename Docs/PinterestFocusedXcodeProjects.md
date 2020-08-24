# Pinterest iOS Development Xcode project usage

XCHammer has several configuration options which support many use cases and this
document outlines how Pinterest uses XCHammer.

### Bazel building Xcode projects

Originally the API for XCHammer included an yaml file and a program that read
the yaml file and generated a project. This was a nice and simple system, but
had several limitations and tradeoffs.

Recently, `xcode_project` rules were introduced which allows Bazel to build
Xcode projects. Bazel  makes it easy both describe Xcode projects via a skylark
DSL and to cache large Xcode projects via local cache and remote cache.

When changes land into master, Xcode projects are built, and developer can
cache hit the project. This helps make large Xcode projects generate
fast.

An original limitation with project generation was knowing "when" to update the
project. Originally, the developer was required to run xchammer after git
checkouts which led to broken indexing and builds. Later, support was added to
automatically update Xcode projects, which included a complex _and_slow_
algorithm. By utilizing Bazel cache facilities and incremental build abilities
we cut nooped generation time down from 3s to a couple hundred milliseconds.

XCHammer will retain support of the original design as it allows people to try
out XCHammer quite easily and is good for simple apps.

### Xcode Project Configuration

Originally, we stored configuration information in a yml representation of
XCHammerConfig. This became hard to manage, and was [refactored to a skylark
DSL](https://github.com/pinterest/xchammer/pull/133)
to make it easier to specify several options.


An example of this is our build instrumentation statsd reporting system, which
is tacked on internally. It ties into schemes by adding `execution_actions` to
run pre/post build

```
log_build_start_action = execution_action(
    name = "Track build start",
    script = "tools/instrumentation_helpers/log_build_start.py",
)
```

Longer term we realized this wouldn't scale for the large number of diverse
testing types. Xcode target settings are composed onto the build graph and
specified adjacent to the Xcode target, mainly through custom macros. XCHammer
aggregates all Xcode configuration for included targets [via an
aspect](https://github.com/pinterest/xchammer/pull/192) which makes Xcode
configuration composeable. By convention, the DSL is declared via macros
adjacent to related BUILD files, e.g. for an an app declared at
`Pinterest/iOS/App/BUILD`, the Xcode configuration is declared at
`Pinterest/iOS/App/XcodeProjectConfig.bzl`. The main BUILD file imports all of
the configuration macros.

### "XCFocus" aka focused projects

Pinterest has a lot of source files which makes building, project generation,
and indexing slow. We use Bazel locally to maximize caching and paralleism of
clang invocations.

Within the `XCHammerConfig` directory, users declare Xcode projects via the
`xcode_project` rule in a way that's ignored from SCM. By default we focus by
target and path to succinctly filter a subset of # transitive dependencies for
specified targets.

```
# XCHammerConfig/Focus.bzl
xcode_project(
    targets = [ ":PinterestDevelopment" ],
    paths = [ "Pinterest/**" ],
)
```

After editing the focused file, the Xcode project automatically is updated.


Generation time for focused are an order of magnitude faster the generating our
entire Xcode workspace.


### Indexing

Like instrumentation, we import indexes into the Xcode project via scheme
actions. After a build, an sync task is triggered that index-imports the index
into Xcode. It uses [`index-import`](https://github.com/lyft/index-import) to
rewrite the Bazel compilation directory to the users current working directory.

As XCHammer Xcode projects are designed to reproduce Bazel build via Xcode
build, incremental indexing works as we type. Xcode picks up compiler settings
from Xcode build targets.

### Run Bazel built tests with Xcode

Xcode has deep integration into the test running system which adds complexity
into how Bazel targets are integrated into the Project. In the original
implementation of Xcode testing Bazel builds, the test bundle and optionally
application are built with Bazel. Xcode is given a `TEST_HOST` environment
variable pointing at the Bazel built application, which allows Xcode to setup
the test and app.

In order for "Focused" tests to run e.g. running a single test via the dot on
the side, Xcode needs a reference to each file under test within the project.
This adds complexity around indexing, and compiling, as we compile with Bazel.
In order to pass XCBuild's output checking, we provide compilers and linkers
that produce dummy output and exit 0. See the following section for more
information.

### Bazel integration

XCHammer leverages both Tulsi's aspect code and build script. It creates
buildable targets that use Bazel as the build system.

This approach has many drawbacks and works without replacing XCBuild. The
current plan is to replace XCBuild with a more Bazel aware build system that
doesn't require this hack, can dynamically build and assemble Bazel targets, and
report status to the user.

### Falling back to Xcode ( Legacy Mode )

Bazel buildable / focused projects have several advantages to original XCHammer
projects including faster build times, indexing times, and generation times.
It's a fundamentally different / better experience. However, under some
situations there may be a reason e.g. developer preference to use the Xcode
building projects. We provide the option to do Xcode builds locally at the cost
of slower experience.

