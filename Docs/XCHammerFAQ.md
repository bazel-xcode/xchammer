## XCHammer Frequently Asked Questions

## Why XCHammer?

Many features in Xcode rely on the fact that Xcode is both the editor and build
system. Since XCHammer builds Bazel projects both Xcode and Bazel as a core
design goal, it supports all of these features by default.

_XCHammer generates an Xcode project from Bazel rules, which we've found to be a
great way to describe an Xcode project and corresponding apps!_

Since Xcode relies on the project configuration for semantic IDE features, like
code completion and diagnostics, correctly setting up the Xcode configuration is
a requirement. From the developers perspective, the Xcode build is functionally
equivalent to the Bazel one: optimizations, files, errors, and warnings are
identical.

## What is XCHammer?

Please see the document, [XCHammer Overview](XCHammerOverview.md)

## How is XCHammer different than Tulsi?

Despite Tulsi being a core _dependenecy_ of XCHammer, they produce very
different results.

#### Generated Projects

Both Tulsi and XCHammer produce Xcode projects. Tulsi produces a project which
contains a minimal set of sources. When Pinterest first migrated, developers
were surprised to see missing types that used to be in the original project.

In addition to generating an Xcode project that calls `bazel build`, XCHammer
can also generate a _pure_ Xcode project. This output project builds primarily
with Xcode. This makes it beneficial for building beta features before Bazel has
supported a feature. Because XCHammer projects build with Xcode or Bazel, the
project should contains _all_ of the sources types, images, localization files,
and assets.  While this is slower to generate, many developers are willing to
wait for the full result.

Additionally developers were spending a lot of time generating Xcode with
projects. In later iterations XCHammer was made incremental by allowing the
project to be split into many projects, focused Xcode projects, and nooping of
generation.

#### Interface

XCHammer provides both a Bazel rule and CLI to build Xcode projects and Tulsi is a
primarily a GUI and CLI application. There's a couple silly hacks that make this
possible, but the authors have found this interface to integrate well with the
XCHammer DSL.

_The XCHammer authors appreciate and stand on the shoulders of contributions from
the Tulsi team!_

## How is XCHammer versioned?

XCHammer aims to be compatible with the latest official version of Bazel,
`rules_apple` and `rules_swift`.

For Apple based development, XCHammer depends on attributes of
[`rules_apple`](https://github.com/bazelbuild/rules_apple). The current, tested,
version is updated in the [sample
WORKSPACE](https://github.com/pinterest/xchammer/blob/master/sample/UrlGet/WORKSPACE).

## Build System Integration

### How can I build files before Xcode's build system runs?

In Xcode build target schemes, XCHammer runs Bazel before compilation to create
generated resources (header maps, source files, custom genrules, etc).

It utilizes the [tag feature in
Bazel](https://docs.bazel.build/versions/master/be/common-definitions.html#common.tags)
Bazel to determine what builds. Rules tagged `xchammer` are queried for at
generation time, and built at build time.

_To keep generation time fast, XCHammer does the minimum amount of work at
generation time. Source files will show up as missing (red), but will be
populated after the first Bazel build.._

## Development

### How can I develop and debug XCHammer?

The `Makefile` contains commands for development and distribution. `make run` and
`make run_force_bazel` both run the sample app with a debug build.

*The sample is a great way to do development on, and the authors recommend
adding examples of edge cases and bugs here :). Pull requests welcome!*


### XCHammer local repository integration

When pulling in XCHammer with `git_repository` and building it in tree, simply
override it with a local repository in the iOS repo's build or `.bazelrc`

```
build --override_repository=xchammer=/path/to/xchammer/
```

### XCHammer binary WORKSPACE integration for development

For binary integration / out of tree builds, `make xchammer_dev_repo` allows a
`WORKSPACE` to consume XCHammer built out of tree but point to the latest build,
symlinked in `bazel-out`. Add to the repository in question:
```
build \
    --override_repository=xchammer=/path/to/xchammer/bazel-out/darwin_x86_64-dbg/bin/xchammer_dev_repo
```

This makes it easy and pain free to build XCHammer outside of the repo but pull
it into the `WORKSPACE`

### Debugging XCHammer Bazel rules in Xcode

1. In the iOS repository, override `xchammer` in the `.bazelrc` to point to the
artifact or local source repository in question, for using the dev repo as
mentioned above:
```
build \
    --override_repository=xchammer=/path/to/xchammer/bazel-out/darwin_x86_64-dbg/bin/xchammer_dev_repo
```

2. In XCHammer repo, run `make workspace_v2 && open workspace_v2.xcodeproj`

3. Change XCHammer Scheme to `wait for executable to launch`

4. Hit the play button

5. Trigger project gen in the iOS repository via bazel ( e.g. `bazlisk build
:MyProject`, `make xcode_focus`, or whatever way you build the Xcode project) 

Note: The rule `xcode_project` is cache invalidated so the binary doesn't run
everytime you build with Bazel. This means if you want to constantaly re-run the
binary you'll need to remove the outputs each time. For example, for the Bazel
target `//:FocusXcodeProj` and project `Focus.xcodeproj`
```
rm -rf bazel-bin/Focus.xcodeproj && bazel build :FocusXcodeProj
```

### How should I contribute to XCHammer?

Pull requests are always welcome! Please submit a PR to [XCHammer's Github](https://github.com/pinterest/xchammer).

Additionally, run `make run_force` with any PR to reflect your changes. _This
command will produce a result that hardcodes paths on your machine into the
project. Don't mind that. Future work will involve addressing that_.

### What tests need to pass before my PR is acceptable?

If you've modified any Bazel files (bzl, BUILD, ...) run `make format` to automatically format those to the Bazel style conventions.

Run `make test` to run all test cases for XCHammer.

_Note: Pinterest runs on the `HEAD` of XCHammer. We require all XCHammer edge
cases in the Pinterest Xcode projects to be exemplified on Github. In short,
just `make test`._

### How can debug the CLI of XCHammer in Xcode?

1. Generate the Xcode project in XCHammer repo locally: run `make workspace_v2 && open workspace_v2.xcodeproj`

2. *Running*
To run XCHammer from Xcode for a given workspace, correctly setup the scheme for
running. Set absolute paths to the `WORKSPACE` via `--workspace_root`,
`XCHammerConfig` ( the first argument ), and `--bazel`. All 3 of these arguments
are required.

```
1)  generate 
2)  /path/to/UrlGet/XCHammer.yml 
3)  --workspace_root /path/to/UrlGet/
4)  --bazel /path/to/bazel/binary
```


## Misc

### How can I build XCHammer with Bazel?

_The canonical, tested, build system of XCHammer is `make`. Bazel support is
currently under development._

Add the following to `WORKSPACE` file
```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "xchammer",
    remote  = "https://github.com/pinterest/xchammer",
    tag = "0.2"
)

load("@xchammer:third_party:repositories.bzl", "xchammer_dependencies")

xchammer_dependencies()
```

Then, run `bazel build @xchammer//:xchammer` to compile from source to build a
debug version.

For release builds, build with compiler optimizations including setting
`--compilation_mode=opt`.
