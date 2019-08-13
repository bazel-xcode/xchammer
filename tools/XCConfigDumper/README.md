# XCConfigDumper

dumps diagnostic settings from `Xcode` build

## Usage

```shell
OVERVIEW: Xcode diagnostic parameters dumper

USAGE: dumper <options>

EXAMPLE: xcodebuild -configuration Debug -project Test.xcodeproj | swift run dumper --output-bazel-config Diag.bzl

OPTIONS:
  --output-bazel-config   A bazel output config. Prints to stdin if not provided
  --xcode-log             An xcode build log. Reads from stdin if not provided
  --help                  Display available options
  ```
