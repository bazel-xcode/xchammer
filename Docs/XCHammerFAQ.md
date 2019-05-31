## XCHammer Frequently Asked Questions

## Why XCHammer?

Many features in Xcode rely on the fact that Xcode is both the editor and build
system. Since XCHammer builds Bazel projects both Xcode and Bazel as a core
design goal, it supports all of these features by default.

_XCHammer generates an Xcode project from Bazel rules, which we've found to be a
great way to describe an Xcode project and corresponding apps!_

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

### How can I develop XCHammer?

The `Makefile` contains commands for development and distribution. `make run` and
`make run_force` both run the sample app with a debug build.

*The sample is a great way to do development on, and the authors recommend
adding examples of edge cases and bugs here :). Pull requests welcome!*

### How can I develop XCHammer with Xcode?

_note: Swift XCHammer Xcode projects are currently under development._

To generate an Xcode project, use the make command, `make workspace`. 

*Running*
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

