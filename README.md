# XCHammer
> If all you've got is Xcode, your only tool is a 🔨

[![Build Status](https://travis-ci.org/pinterest/xchammer.svg?branch=master)](https://travis-ci.org/pinterest/xchammer)

XCHammer generates Xcode projects from a [Bazel](https://bazel.build/) Workspace.

- [x] Complete Bazel Xcode IDE integration
    - [x] Bazel build and run via Xcode
    - [x] Xcode test runner integration
    - [x] Full LLDB support without DSYM generation
    - [x] Autocompletion and indexing support
    - [x] Renders Bazel's progress in Xcode's progress bar
    - [x] Optionally import index's via [index-import](https://github.com/lyft/index-import) with [Run Scripts](sample/UrlGet/BUILD.bazel#L39)
    - [x] Customize Bazel invocations for Xcode
- [x] [Focused](Docs/PinterestFocusedXcodeProjects.md#xcfocus-aka-focused-projects) Xcode projects
- [x] Xcode build Bazel targets _without Bazel_
- [x] Optionally Bazel build Xcode projects
   - [x] Define and compose Xcode projects [in Skylark](#bazel-build-xcode-projects)
   - [x] Builds reproducible and remote cacheable projects
- [x] Automatically updates Xcode projects

## Usage

_Note: this README is intended to be a minimal, quick start guide. For a comprehensive explanation of XCHammer, see [Introducing XCHammer](Docs/FastAndReproducibleBuildsWithXCHammer.md) and [The XCHammer FAQ](Docs/XCHammerFAQ.md)_

### Installation

Build and install to `/usr/local/bin/`

```bash
make install
```

_Pinterest vendors XCHammer.app for reproducibility and simplicity._


### Configuration

Generate using a [XCHammerConfig](Sources/XCHammer/XCHammerConfig.swift).

```bash
xchammer generate <configPath>
```

## Configuration Format

XCHammer is configured via a `yaml` representation of [XCHammerConfig](https://github.com/pinterest/xchammer/blob/master/Sources/XCHammer/XCHammerConfig.swift).

The configuration describes projects that should be generated.

```yaml
# Generates a project containing the target ios-app
targets:
    - "//ios-app:ios-app"

projects:
    "MyProject":
        paths:
            - "**"
```

_See [XCHammerConfig.swift](https://github.com/pinterest/xchammer/blob/master/Sources/XCHammer/XCHammerConfig.swift) for detailed documentation of the format._

_To learn about how Pinterest uses XCHammer with Bazel locally check out [Pinterest Xcode Focused Projects](https://github.com/pinterest/xchammer/blob/master/Docs/PinterestFocusedXcodeProjects.md)._

## Samples

- [a Objective-C iOS app](sample/UrlGet)
- [a Swift iOS app](sample/Tailor) 
- [a Swift macOS app](BUILD.bazel)

## Bazel build Xcode projects

XCHammer additionally supports Bazel building Xcode projects, which enables
remote caching and other features. This feature is experimental.

```py
# WORKSPACE
local_repository(
    name = "xchammer_resources",
    path = "/Path/To/xchammer.app/Contents/Resources",
)

# BUILD.Bazel
load("@xchammer_resources//:xcodeproject.bzl", "xcode_project")
xcode_project(
    name = "MyProject",
    targets = [ "//ios-app:ios-app" ],
    paths = [ "**" ],
)
```

### Xcode progress bar integration

XCHammer provides a path to optionally integrate with Xcode's build system and
progress bar.

- Install support for Xcode's progress bar for Xcode 11

```
xchammer install_xcode_build_system
```

- add `--build_event_binary_file=/tmp/bep.bep` to your `.bazelrc`
- make sure Xcode's new build system is enabled


## Development

Please find more info about developing XCHammer in [The XCHammer FAQ](Docs/XCHammerFAQ.md). Pull requests welcome 💖.
