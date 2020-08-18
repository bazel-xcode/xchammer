# Bazel for iOS Developers

This document is an introduction to Bazel for iOS developers. While there's
been many docs written about Bazel, the existing material can be overwhelming
for a line engineer looking to get started. This document is geared towards an
iOS developer coming from Xcode and intends to be a lightweight introduction to
Bazel.

The document supplements canonical Bazel resources, linked in the [conclusion](#conclusion).

## Table of contents

* [Bazel for iOS Developers](#bazel-for-ios-developers)
  * [Table of contents](#table-of-contents)
  * [Build systems for iOS developers](#build-systems-for-ios-developers)
  * [Bazel projects](#bazel-projects)
     * [Setting up a WORKSPACE](#setting-up-a-workspace)
     * [Adding an iOS application with BUILD files](#adding-an-ios-application-with-build-files)
     * [Bazel command line](#bazel-command-line)
     * [Configurable build attributes](#configurable-build-attributes)
     * [Compiler configuration](#compiler-configuration)
  * [Extending Bazel](#extending-bazel)
     * [Starlark](#starlark)
     * [Rules](#rules)
     * [Macros](#macros)
     * [Aspects](#aspects)
     * [Toolchains](#toolchains)
     * [Generated Xcode projects](#generated-xcode-projects)
  * [More information](#more-information)
     * [Gathering information with Bazel query](#gathering-information-with-bazel-query)
     * [Fixing common Bazel errors](#fixing-common-bazel-errors)
     * [Installing Bazel](#installing-bazel)
     * [Building CocoaPods with Bazel](#building-cocoapods-with-bazel)
  * [Conclusion](#conclusion)


## Build systems for iOS developers

First, let's address the definiton of a "Build system". According to [Stack
overflow](https://stackoverflow.com/questions/7249871/what-is-a-build-tool_):
> Build tools are programs that automate the creation of executable applications
> from source code (e.g., `.apk` for an Android app). Building incorporates
> compiling,linking and packaging the code into a usable or executable form.

In iOS development, Apple encapsulates build systems inside of Xcode. Xcode is
both the IDE _and build system_. For many developers, Xcode just works. To have
a good experience, most developers don't need to worry about implementing build
systems, IDEs, or compilers. When the project scales, developer experience
drops off. Tasks like building, indexing, or merging a change that adds a new
file can become painful. 

Bazel can fix many problems with iOS builds when done well. First, Bazel is
strict about inputs and outputs - they must be declared. This property, known as
"hermetic" builds, makes builds reproducible and well-suited for distributed
cloud builds and caching. For developers, this means better performance due to
cache hitting and not constantly removing derived data. Clean builds become
incremental, decades of CPU cycles saved.  Bazel also makes it easy to automate
many kinds tasks for example, code generating a thrift schema, [generating an
Xcode project](https://github.com/pinterest/xchammer), or [pushing a docker
container](https://github.com/bazelbuild/rules_docker).  Starklark, a built in
determinsitc python-like programming language allows developers to implement
custom build logic. For developers this means better performance and pulling in
ad-hoc build tasks into a directed build graph.

_To learn about how Bazel compares to other build systems, Microsoft's paper
[Build Systems à la
Carte](https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf),
compares popular build systems._

## Bazel projects

The root of a Bazel project contains two human-readable files:

The `BUILD` file: defines what targets are inside of a project.
Applications, extensions, static libraries, and frameworks are all declared in
BUILD files.

The `WORKSPACE` file: references files and dependencies from
[outside the world into
Bazel](https://docs.bazel.build/versions/master/be/workspace.html).  Simply
put, external-to-the-repository dependencies are put here. 

_In the Xcode world, build configuration is governed by the Xcode GUI and
stored in the machine readable `xcodeproj` files._

### Setting up a WORKSPACE

For building iOS applications, most iOS developers use the rule set
`rules_apple`. `rules_apple` contains key [rules](#rules) for iOS development which
includes rules to build applications, unit tests, and more.

Head to [rules_apple](https://github.com/bazelbuild/rules_apple) and follow the
latest instructions to get setup. `rules_apple` provides instructions to add
dependencies into the `WORKSPACE` file. Simply paste the lines from
`rules_apple`'s README into the `WORKSPACE` file

```
# /path/to/myproject/WORKSPACE
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "build_bazel_rules_apple",
    remote = "https://github.com/bazelbuild/rules_apple.git",
    commit = "[SOME_HASH_VALUE]",
)
```

The first line of code calls the function, `load`. The load function imports
symbols from a `.bzl` file.  It's like importing a header file
in Objective-C or Swift.

```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
```
_load `git_repository` from the internal [bazel tools](https://github.com/bazelbuild/bazel/issues/4301) repository_

The next line of code calls `git_repository` and defines the repository
`build_bazel_rules_apple` from the git repository,
`https://github.com/bazelbuild/rules_apple` for a given `commit`. 

### Adding an iOS application with BUILD files

`BUILD` files are where all the targets are defined. For Apple developers, this
often includes apps, tests, app extensions, frameworks, and libraries.

First, let's walk through creating a basic iOS application. In the root of the
project, let's create the `BUILD` file. First, a library for the iOS
application sources. The following code defines an `objc_library`, `sources`.

```
# /path/to/myproject/BUILD
objc_library(
    name="sources",
    srcs=["main.m"]
)
```

Next, create the application target with `rules_apple`'s `ios_application` rule.
```
# /path/to/myproject/BUILD
...
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
ios_application(
    name = "ios-app",
    bundle_id = "com.bazel-bootcamp.some",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "[MINIMUM VERSION]",
    # Add `sources` as a dependency
    deps = [ ":sources" ],
)
```

In Xcode this is similar to navigating in the GUI and hitting `File -> New
Target`. Together, the `ios_application` and `objc_library` targets together
would be represented in Xcode as:

![Docs](XcodeExampleOfiOSProject.png)
	
### Bazel command line

In Xcode, command line builds are achieved through the command line interface
`xcodebuild`.  to build the scheme `ios-app` from `MyProject.xcworkspace`,
`xcodebuild`, would be invoked as:

```
xcodebuild -workspace MyProject.xcworkspace -scheme ios-app
```

Bazel exposes a command line which can also do builds. In Bazel, _every_ target
is in the global WORKSPACE and there is no notion of schemes.

```
bazel build ios-app
```

The Bazel command line has hundreds of options, which can be found in the
[Bazel
documentation](https://docs.bazel.build/versions/master/command-line-reference.html).
For iOS developers, a set of useful flags is available at
[bazel-ios-users](https://github.com/ios-bazel-users/ios-bazel-users/blob/master/UsefulFlags.md).

### Configurable build attributes

In addition to the default Bazel options, it's common to create custom
configuration settings to customize builds. Together, `select` and
`config_setting` yield configurable build attributes.

For example, the following build file has conditional `copts` on `:app_store`

```
objc_library(
   name = "some",
   srcs = ["some.m"],
   copts = select({
      # For app_store we need to build `some.m` with a special copt
      ":app_store": ["-DAPPSTORE=1"],
      "//conditions:default": [],
    })
)
config_setting(
    name = "app_store",
    values = { "app_store" : "true" }
)
```

This can be set as a define and passed to Bazel on the command line

```
bazel build ios-app --define app_store=true
```

For more information about `select` and `config_setting`, please see the [Bazel
documentation](https://docs.bazel.build/versions/master/be/common-definitions.html#configurable-attributes).

### Compiler configuration

In Xcode there is a plethora of configuration options known as xcconfig that
implicate different compiler flags.  In Bazel, `toolchains`, `objc_library`,
`bazelrc` all configure flags. The variable `copts` in `objc_library` passes
flags directly to the compiler. Please find canonical documentation on `copts`
on the [Bazel
docs](https://docs.bazel.build/versions/master/be/objective-c.html#objc_library.copts).
Using `objc_library` to define compiler flags is useful for the per-rule level
and many projects use macros and other layers of abstraction to [unify library
level configuration](#Macros).


## Extending Bazel

### Starlark

Bazel provides the
[_pythonic_](https://stackoverflow.com/questions/25011078/what-does-pythonic-mean)
programming language, Starlark. Starlark is used to implement build system
logic and establish norms.  Generally, Starlark calls into functionality that's
implemented within Bazel. The coming segments [rules](#rules),
[macros](#macros), and [aspects](#aspects) cover several examples.

```
.bzl file -> starlark -> bazel functions
```

Starlark enables extensibility without needing to fork the core build system.
This boundary helps the developer to focus on their business logic instead of
the core of the build system. For example, the Apple-specific logic of bundling
an `ios_application` is defined outside Bazel's core by `rules_apple`.

With Starlark, the possibilities are endless. _technically they aren't endless
as the language is not Turing complete_. For more information, please see the
[Starlark
documentation](https://docs.bazel.build/versions/master/skylark/language.html).


### Rules

Rules implement business logic for how the iOS application is built by creating
actions. Actions represent invocations of external command line programs like
`clang` or `bash`. Instances of rules are targets. Typical projects contain many
rules, targets, and BUILD files.

> A rule defines a series of actions that Bazel performs on inputs to produce a set of outputs.

_- [the bazel documentation](https://docs.bazel.build/versions/master/skylark/rules.html)_


In the previous segment, we created an iOS application with a BUILD file.
The `ios_application` rule is implemented by `rules_apple` and the
`objc_library` is a native rule. Native rules are implemented in Java, have
more power and capabilities needed to implement core functionality (like remote
execution and C++ compilation), and are generally used as-is.

```
BUILD file -> target -> rule -> action -> execution
```

Bazel and open source rules should provide most functionality to build an iOS
application. Generally, defining custom rules isn't required but can improve and
consolidate functionality. To learn more about how to create custom rules, the
document, [Bazel
extensions](https://docs.bazel.build/versions/master/skylark/concepts.html)
contains a comprehensive overview.

### Macros

Like [rules](#Rules) and [aspects](#Aspects), macros are
defined in `.bzl` files.  A macro is a convenient way to call a rule, and not
recognized by Bazel in the same way a rule is.

_Note: The main distinction between a `.bzl` and a `BUILD` file is `BUILD` files are
used to create targets by calling macros and rules. `.bzl` files define the
implementation._

Most users of Bazel implement a higher level system of macros to encapsulate
defaults of building libraries and simplify configuration management. To create
a wrapper for `objc_library`, create the file `objc_library.bzl`. The following
macro restricts the customization, and enforces defaults of the native
`objc_library` rule.

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

By loading our `objc_library` into a `BUILD` file, it will override the native
`objc_library` rule, which is automatically imported.
```
load(":objc_library.bzl", "objc_library")

# This calls the custom objc_library macro. Thankfully, building this with
# Bazel will error out due to the unavailable argument `copts` used here.
objc_library(name="some", copts=["-DSOME"])
```

The same principles can be applied to many rules: wrapping macros with macros.
Please see the
[`objc_library`](https://docs.bazel.build/versions/master/be/objective-c.html)
documentation for all possible arguments. _Note: Unlike Starlark rules which
are easily added on to Bazel, the `objc_library` is part of the internal Java
rules shipped with the Bazel
binary._ 

_In the Xcode world, configuration is defined within Xcode projects and
proprietary xcconfigs. In Bazel it's easy to establish norms, enforce
consistency with abstractions like `objc_library`, and refactor_

### Aspects

Aspects are another extension point in Bazel. Simply put, they allow the
developer to traverse the build graph and collect information or generate
actions on the way. 

> Aspects are a feature of Bazel that are basically like fan-fic, if build rules
were stories: aspects let you add features that require intimate knowledge of
the build graph, but that that the rule maintainer would never want to add.

_- [Kristina Chodorow, Aspects: the fan-fic of build rules](https://kchodorow.com/2017/01/10/aspects-the-fan-fic-of-build-rules/)_

Combined with rules and the Bazel command line, the user is able to create robust
architectures and powerful abstractions. Like rules, generally, defining custom
rules isn't required but can improve and consolidate functionality. For more
information about aspects, see [Aspects the fan-fic of build
rules](https://kchodorow.com/2017/01/10/aspects-the-fan-fic-of-build-rules/)

### Toolchains

In addition to configuring the build with rules, Bazel provides an additional
primitive: the toolchain. Toolchains provide default compilers and arguments
for those compilers. For the native C++ rules, toolchains configure
the many flags required for cross compilation.

For most iOS projects, configuring the C++ toolchain isn't required. Defining a
custom toolchain gives full control over compiler invocations or
to customize the compiler being invoked.  Please see the [toolchain
documentation](https://docs.bazel.build/versions/master/tutorial/cc-toolchain-config.html)
to learn more.

### Generated Xcode projects

In an Xcode world, engineers check in a project file, which contains a listing of
source files, build settings, and IDE state. As the codebase scales, the project file
model breaks down, particularly when auditing and code reviewing config changes. With Bazel, human readable `BUILD` files are the
source of truth for build and Xcode configuration. Tools like
[XCHammer](https://github.com/pinterest/xchammer), and
[Tulsi](https://github.com/bazelbuild/tulsi) use an aspect to traverse the
build graph and extract metadata required to generate a project.  These tools
make it easier to manage the project and generate on demand - not needing to
check it in.

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

Like any other Bazel target, it's built from the command line:
```
bazel build :MyProject
```

The rule definition for the `xcode_project` may be found in the [github
repository](https://github.com/pinterest/xchammer/blob/master/BazelExtensions/xcodeproject.bzl).
Simply put, the aspect traverses sources, and invokes the `xchammer` binary with
a JSON file. Internally, XCHammer instantiates
[XcodeGen](https://github.com/yonaskolb/XcodeGen) types and writes them out to
disk with [xcodeproj](https://github.com/tuist/XcodeProj).

Generating an Xcode project with XCHammer:
```
command line -> bazel -> rule -> xchammer -> xcodegen -> project.xcodeproj
```

Generators like XCHammer and Tulsi take care of integrating Bazel into the IDE.
Bazel builds are invoked a shell script build phase from the IDE. Basically,
Xcode shells out to Bazel to produce the application, and then Xcode picks up
the product from the derived data path. 

Performing a Bazel build from Xcode:

```
play button -> shell script build phase -> bazel build ios-app
```

![Docs](XcodeBazelRunscript.png)

_In the Xcode world, Xcode's internal build systems produce the application._

## More information

### Gathering information with Bazel query

Bazel query is command line interface that uses a DSL designed to query the
build graph and extract information. This can be used for tooling purposes, or
to simply questions about the build. Here's a few examples:

What extensions does the target `pinterest` depend upon?
```
bazel query 'kind(ios_extension, deps(pinterest))'
```

What are the labels of source files in `app-lib`?
```
bazel query --noimplicit_deps 'labels(srcs, app-lib)'
```

Please see the [Bazel query
documentation](https://docs.bazel.build/versions/master/query.html) for more
information.

### Fixing common Bazel errors

This segment indicates how to fix a basic Bazel error.

Bazel has a few levels of validation which often occur at BUILD time. Note that
since Bazel doesn't type check all files in the WORKSPACE on every build it's
possible to have an error in one target, while other targets still work.

```
ERROR: /path/to/myproject/BUILD:4:13:
objc_library() got unexpected keyword argument: copts
```

In the hypothetical file `/path/to/myproject/BUILD`, at the line `4:13` got an
unexpected keyword argument, `copts` to the macro `objc_library`. The erroneous
code resides in the example in the [macros](#macros) segment, which calls a
custom `objc_library` macro. The macro only exposes the parameters `name`,
`srcs`, `hdrs`, `deps`, and `data`. By attempting to pass `copts` and deviate
from the default `copts`, Bazel triggered an error.

If needed, Bazel generally will indicate the `.bzl` file where the issue
occurred and `BUILD` file that created the error in a call stack like fashion.

To actually fix this error, simply remove the unsupported argument `copts`.

 _Note: Bazel's diagnostic
convention is similar to how clang and Swift errors look and feel inside of
Xcode._ 

### Installing Bazel

Bazel is commonly invoked via a wrapper script to handle downloading and
installing Bazel binaries at the correct version. To implement reproducible
builds, every dependency should be pinned at a commit, including Bazel. BUILD
files, rules, and protocol buffers, are often tied to a certain release of
Bazel. An popular example of a wrapper script is
[Bazelisk](https://github.com/bazelbuild/bazelisk/releases). Bazelisk allows
the user to specify a `.bazelversion` file at the root of the project and
easily update. To work across many Bazel projects, it's convenient to install
`Bazelisk` onto the path, and invoke it as `bazel`. 

_Note: In order for Bazel's
shell completion to work, the wrapper script must be named `bazel`._

### Building CocoaPods with Bazel

`PodToBUILD` provides a WORKSPACE rule to make it easy to build CocoaPods with
Bazel. It loads in sources, and by reading in a Podspec file, it can generate a
BUILD file. Find out more information about [PodToBUILD on
github](https://github.com/pinterest/PodToBUILD). 


## Conclusion

This concludes the iOS flavored introduction to Bazel. For more information,
the Bazel documentation contains up-to-date tutorials, in-depth knowledge, and
more.

- [Bazel overview](https://docs.bazel.build/versions/master/bazel-overview.html)
- [A tutorial for iOS apps](https://docs.bazel.build/versions/master/tutorial/ios-app.html) 
- [Bazel Concepts and terminology](https://docs.bazel.build/versions/master/build-ref.html)
- [Getting started with Bazel](https://docs.bazel.build/versions/master/getting-started.html) 
- [Rules](https://docs.bazel.build/versions/master/rules.html)
- [Encyclopedia](https://docs.bazel.build/versions/master/be/overview.html)
- [Starlark](https://docs.bazel.build/versions/master/skylark/language.html)

The community maintains repos and documentation
- [Awesome Bazel](https://github.com/jin/awesome-bazel)
- [ios-bazel-users](https://github.com/ios-bazel-users/ios-bazel-users)
- [Useful Xcode Knowledge](https://github.com/ios-bazel-users/ios-bazel-users/blob/master/UsefulXcodeKnowledge.md)
- [Line's Apple rules](https://github.com/line/rules_apple_line)
- [iOS rules for Bazel - Square, Linkedin](https://github.com/bazel-ios/rules_ios)

Finally, this document is meant to be updated. If there are additional bullet
points useful for iOS developer onboarding, please send a pull request. 
