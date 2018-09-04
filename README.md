# XCHammer

XCHammer generates Xcode projects from a [Bazel](https://bazel.build/) Workspace.

## Usage

First install XCHammer
```
make install
```

Generate using a [XCHammerConfig](https://github.com/pinterest/xchammer/blob/master/Sources/XCHammer/XCHammerConfig.swift). 
```
xchammer generate <configPath>
```

## Configuration Format

XCHammer is configured via a `yaml` representation of [XCHammerConfig](https://github.com/pinterest/xchammer/blob/master/Sources/XCHammer/XCHammerConfig.swift).

The configuration describes projects that should be generated.

```
# Bazel targets to generate
targets:
    - "//ios-app:ios-app"

# The projects to generate
projects:
    "iOSProject":
        # Source file paths to include
        paths:
            - "Vendor/**"
            - "ios-app/**"
```
*Generate a single project containing the target ios-app*

See [XCHammerConfig.swift](https://github.com/pinterest/xchammer/blob/master/Sources/XCHammer/XCHammerConfig.swift) for detailed documentation.

## Versioning

XCHammer releases correspond to a tested, canonical, Bazel release.

For Apple based development, XCHammer depends on attributes of
[`rules_apple`](https://github.com/bazelbuild/rules_apple). The current, tested,
version is updated in the [sample
WORKSPACE](https://github.com/pinterest/xchammer/blob/master/sample/UrlGet/WORKSPACE).

## Sample

The sample directory contains [a fully functioning iOS app](https://github.com/pinterest/xchammer/blob/master/sample/UrlGet).

## Development

The `Makefile` contains commands for development and deployment.

Pull Requests welcome :).

