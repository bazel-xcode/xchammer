# Bazel for iOS Developers

This document is an introduction to Bazel for iOS developers. There's a few
other resources available for Bazel as well:
- https://docs.bazel.build/versions/master/tutorial/ios-app.html

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

WORKSPACE - this is about getting files and dependnecies from outside the world
into Bazel
https://docs.bazel.build/versions/master/be/workspace.html

BUILD files, these files define how a project builds.

## WORKSPACE configuration and setting up rules apple

For building iOS applications, most iOS developers use the bazel rules,
`rules_apple`. This ruleset has a few key rules for iOS development which
include building applications and unit tests.

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
imports symbols from a Bazel file to make availabe. Simply put it tells Bazel
that during the loading sequence, it should import symbols. In Cbjective-C or
swift, it's like importing a header file, but specific symbols out of that
header.
```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
```
_load `git_repository` from the internal bazel tools repository_

The next line of code calls `git_repository` defines `build_bazel_rules_apple`
from the git repository, `https://github.com/bazelbuild/rules_apple` for a
given `commit`. 

_`git_repository` documentation https://docs.bazel.build/versions/2.0.0/repo/git.html_

## BUILD file configuration

The BUILD file is where all the rules are declared. Rules implement business
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
    bundle_id = "com.bazel-bootcaamp.some",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "[MINIMUM VERSION]",
    deps = [ ":sources" ],
)
```

After fulfilling requirements, e.g. creating `main.m` and the `Info.plist`, the
application can build. 

TODO: determine to template for of main.m or Info.plist somewhere 

### Xcode projects

This segment describes how to build an Xcode project with XCHammer

TODO: Add link for XCHammer usage

## Practical bazel usage


### Configuration of libraries and flags

_objc_library_ configuration. The `objc_library` API provides many arguments for
configuration, after all, the `objc_library` it's self is a configuration.

The documentation resides here
https://docs.bazel.build/versions/master/be/objective-c.html

Toolchains
TODO: Update this doc and link to.
https://github.com/bazelbuild/bazel/wiki/Building-with-a-custom-toolchain

### Fixing common Bazel error

A segment about fixing common error messages

