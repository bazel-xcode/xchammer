# XCHammer
> If all you've got is Xcode, your only tool is a 🔨

[![Build Status](https://travis-ci.org/pinterest/xchammer.svg?branch=master)](https://travis-ci.org/pinterest/xchammer)

XCHammer generates Xcode projects from a [Bazel](https://bazel.build/) Workspace.

## Usage

_Note: this README is intended to be a minimal, quick start guide. For a comprehensive explanation of XCHammer, see [Introducing XCHammer](Docs/FastAndReproducibleBuildsWithXCHammer.md) and [The XCHammer FAQ](Docs/XCHammerFAQ.md)_

### Installation

You can clone the xchammer repository and run the following to build and install on your path.

```bash
make install
```

Alternatively, you can integrate xchammer in your existing bazel project if you prefer to use `bazel run` to invoke xchammer.

Add the following to your `WORKSPACE` file
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

Then you can run `bazel build @xchammer//:xchammer` to compile from source to build a debug version of xchammer.

For production, please build with `--compilation_mode=opt` to significantly speed up project generation times.

### Configuration

Generate using a [XCHammerConfig](https://github.com/pinterest/xchammer/blob/master/Sources/XCHammer/XCHammerConfig.swift).

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

## Sample

The sample directory contains [a fully functioning iOS app](https://github.com/pinterest/xchammer/blob/master/sample/UrlGet).

## Development

Please find more info about developing XCHammer in [The XCHammer FAQ](Docs/XCHammerFAQ.md). Pull requests welcome 💖.

_Connect with the XCHammer team on the #xchammer channel in the [xcode.swift slack](https://join.slack.com/t/xcodeswift/shared_invite/enQtNDIxMjM4MTEzODI2LWVmZGVhNjc4MjM3NTRhM2Q1ZGJhYjI3NjZkNTYzMGYyODNmNWZlMmM3OWNkMWQzZjhkMmM0ODEyOTZmMWI4M2E)._
