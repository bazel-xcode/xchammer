# XCHammer

XCHammer generates Xcode projects from a Bazel Workspace.

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

## Sample

The sample directory contains [a fully functioning iOS app](https://github.com/pinterest/xchammer/blob/master/sample/UrlGet).

## Development

The `Makefile` contains commands for development and deployment.

Pull Requests welcome :).

