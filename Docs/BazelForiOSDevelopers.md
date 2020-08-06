# Bazel for iOS Developers

This document is an introduction to Bazel for iOS developers. There's been many
docs written about Bazel and this document is geared more towards an iOS
application developer coming from Xcode and aims to be a lightweight but
complete introduction and map familiar concepts.

The document supplements canonical resources:
- [A tutorial for iOS apps](https://docs.bazel.build/versions/master/tutorial/ios-app.html)
- [Concepts and terminology](https://docs.bazel.build/versions/master/build-ref.html)
- [Getting started](https://docs.bazel.build/versions/master/getting-started.html)


## Build systems for iOS developers

In iOS development, Apple encapsulates build systems inside of Xcode to build
applications. For many developers, the default Xcode build system is great.
Most iOS developers don't need to worry about the implementation of C++ swift,
and objective C, compilers or how those compilers are invoked. When the build
size grows, developer experience drops off. Having the ability to optimizing the
build system can significantly improve the developer experience. Tasks like
indexing, or making a change that adds or removes a file due to a manually
managed project can get out of hand. Bazel makes it easy to manage all of the
build configuration in a way that results is functional and reproducible.

Compared to other mainstream build systems out there, Bazel is very strict about inputs
which makes it reproducible. In 2018, Microsoft came out with a paper that
compares all the build systems
https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf


# Project files

In the root of Bazel project, there's going to be 2 files atleast

`WORKSPACE` - this is about getting files and dependencies from outside the world
into Bazel
https://docs.bazel.build/versions/master/be/workspace.html

`BUILD` files, these files define how a project builds.

## WORKSPACE configuration and setting up rules apple

For building iOS applications, most iOS developers use the rule set
`rules_apple`. This rule set contains key rules for iOS development which
include building applications, unit tests, and more.

Head to https://github.com/bazelbuild/rules_apple and follow the latest
instructions to get the relevant instructions. `rules_apple` will provide
instructions to add dependencies for the `WORKSPACE` file.

This is typical code in setting up rules, like `rules_apple`
```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "build_bazel_rules_apple",
    remote = "https://github.com/bazelbuild/rules_apple.git",
    commit = "[SOME_HASH_VALUE]",
)
```

Based on the current requirements of `rules_apple`, there's going to be a few
lines of code.

The first line of code calls the function, `load`. The load function
imports symbols from a Bazel file to make them available. Simply put it tells Bazel
that during the loading sequence, it should import symbols. In Objective-C or
swift, it's like importing a header file, but specific symbols out of that
header.
```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
```
_load `git_repository` from the internal [bazel tools](https://github.com/bazelbuild/bazel/issues/4301) repository_

The next line of code calls `git_repository` defines `build_bazel_rules_apple`
from the git repository, `https://github.com/bazelbuild/rules_apple` for a
given `commit`. 

_`git_repository` documentation https://docs.bazel.build/versions/2.0.0/repo/git.html_

## BUILD file configuration

The `BUILD` file is where all the rules are declared. Rules implement business
logic for how the iOS application is built by creating actions. An instance of
a rule is a `target`. A target has a few abilities in Bazel.

First create a library for an iOS application. The following code defines an
`objc_library`, `sources`. In Xcode this is similar to navigating in the GUI and
hitting `File -> New Target` 

```
objc_library(
    name="sources",
    srcs=["main.m"]
)
```

Next, create the app 
```
ios_application(
    name = "ios-app",
    bundle_id = "com.bazel-bootcamp.some",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "[MINIMUM VERSION]",
    deps = [ ":sources" ],
)
```

After fulfilling requirements, e.g. creating `main.m` and the `Info.plist`, the
application can build. 

### Xcode projects

This segment describes how to build an Xcode project with XCHammer

Generally in an Xcode world, folks have checked in a project when can lead to
merge conflicts and be difficult to audit and manage configuration when the
team and project grows. When using Bazel, generally Bazel is the source of
truth for Xcode configuration. Tools like [XCHammer](), and [Tulsi]() use an
aspect to traverse the build graph and extract metata required to generate a
project. These tools make it easier to manage the project and generate on
demand - not needing to check it in.

XCHammer provides a rule to [bazel build Xcode
projects](ihttps://github.com/pinterest/xchammer#bazel-build-xcode-projects).
Simply declare the rule with the project and Bazel build the target.
```
load("@xchammer_resources//:xcodeproject.bzl", "xcode_project")
xcode_project(
    name = "MyProject",
    targets = [ "//ios-app:ios-app" ],
    paths = [ "**" ],
)
```

The rule definition for the `xcode_project` may be found in the [github
repository](https://github.com/pinterest/xchammer/blob/master/BazelExtensions/xcodeproject.bzl).
Simply put, the aspect traverses sources, and invokes the `xchammer` binary
with a JSON file. Internally, XCHammer instantiates
[`XcodeGen`](https://github.com/yonaskolb/XcodeGen) types and writes them out
to disk with `xcodeproj`.


## Practical Bazel usage


### Basic configuration of libraries and flags

## _objc_library_ configuration via macros

The `objc_library` API provides many arguments for configuration, after all, the
`objc_library` it's self is a configuration.  The documentation resides here
https://docs.bazel.build/versions/master/be/objective-c.html

_Note: Unlike skylark easily added on to Bazel, the `objc_library` is part of
the internal java rules shipped with the Bazel binary._ Most users of Bazel
implement a higher level system of macros to encapsulate defaults of building
librarys and simplify configuration management.

Bazel provides the pythonic programming language Starlark to implement build
system logic. Build logic is implemented in rules, aspects, and macros defined
in `.bzl`. The main distinction the 2 files is that is `BUILD` files are used to
define targets by calling macros and rules, and `.bzl` files define the
implementation. A Bazel target is generally an instantiation of a rule in some
form.

To create a wrapper for `objc_library`, define the file `objc_library.bzl`.  The
following macro restricts the customization that users are able to use here, and
enforces defaults. This is somewhat of a composition pattern.

```
def objc_library(name, srcs=[], hdrs=[], deps=[], data=[]):
    """
    An objc_library that turns on pedantic warnings,
    and enables modules
    """
    native.objc_library(
        name=name,
        deps=deps,
        data=data,
        srcs=srcs,
        hdrs=hdrs,
        enable_modules=True,
        copts=[
            "-Wpedantic"
        ]
    )
```

By loading our `objc_library` into a `BUILD` file, it will ovverride the native
`objc_library` rule, which was automatically imported.
```
load(":objc_library.bzl", "objc_library")

# This calls the custom objc_library, and will error out on `copts`
objc_library(name="some", copts=["-DSOME"])
```

The same principals can be applied to many rules: wrapping macros with macros.
With Starlark, the possibilities are endless! _technically they are endless as
the language is not turing complete_.

For more information on implementing rules and macros, check out the [Extension
Overview](https://docs.bazel.build/versions/master/skylark/concepts.html)

_Toolchains_ Bazel uses a combination of [toolchains and crosstool's to manage configuration](https://docs.bazel.build/versions/master/tutorial/cc-toolchain-config.html). 

### Fixing common Bazel errors

This segment indicates how to fix a basic Bazel error. Bazel has a few levels of
validation which often occur at BUILD time. Note that since Bazel doesn't type
check all files in the WORKSPACE on every build it's possible to have an error
in 1 target, while other targets still work.

```
ERROR: /Users/jerrymarino/Projects/xchammer-github/BUILD.bazel:4:13:
objc_library() got unexpected keyword argument: copts
```

In the above code, a rule author defined a custom `objc_library` which only
exposed the parameters name, srcs, hdrs, deps, and data. This is notated by the
file path `/Users/jerrymarino/Projects/xchammer-github/BUILD.bazel` at the line
`4:13` where the error occurred. _This is very similar to how clang and swift
errors look and feel inside of Xcode_ 

If needed, Bazel generally will indicate the `.bzl` file where the issue
occurred and `BUILD` file that created the error in a call stack like fashion.

To actually fix this error, simply remove the unsupported argument `copts`.


