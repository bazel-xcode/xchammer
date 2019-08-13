# XCConfigDumper

dumps diagnostic settings from `Xcode` build
This tool us useful when you need to get compiler settings from new version of `Xcode`

## Usage

1. Create new `Xcode` project.
2. Run `xcodebuild --project /path/to/project/Test.xcodeproj clean && xcodebuild -configuration Debug -project /path/to/project/Test.xcodeproj | swift run xcconfigdumper --output-bazel-config Diag.bzl`

> You should clean the project before running `xcconfigdumper`
