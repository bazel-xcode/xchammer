Introducing XCHammer, Pinterest's Xcode project generator.
<br/>
<br/>
![Docs](XCHammer.svg)

XCHammer generates Xcode projects from Skylark rules to provide an excellent developer experience and enable fast, reproducible builds from Xcode.

## Fast, reproducible iOS builds

Pinterest builds it's iOS app with Bazel for fast, reproducible builds. Bazel is an open source, multi language build system that makes it easy to manage complex build and toolchain configurations and fundamentally improves the stability and performance of the build.

With reproducibility, Bazel takes builds from clean to incremental: prior to Bazel, all CI builds were clean builds.

Xcode VS Bazel head to head CI build time comparison in seconds

- Xcode clean build and unit test time - TBD seconds
- Bazel mean build and unit test time - 242 seconds
- Xcode clean static analysis time - TBD seconds
- Bazel mean static analysis time - 536 seconds

The Bazel build utilizes caching to speed things up. Artifacts cached on a CI machine can safely be reused for subsequent builds. Remote caching provides greater reuse of artifacts. The current implementation of remote caching nets a 30% decrease in mean build time and a 40% decrease in mean static analysis time.

## Generated projects

After a successful Bazel migration, Pinterest needed a way to integrate Bazel into the local development workflow. Traditionally, Xcode projects were checked into the repo along with the source code. This resulted in frequent, painful, merges and hard to review PRs. 

With XCHammer, Xcode projects are generated on the developer's machine. By storing transient projects locally, merge conflicts don't slow down development. Generated projects make it easier to review and reason about configuration changes in readable `BUILD` and `.bzl` files.

### XCHammer Generation Workflow
XCHammer reads in a Bazel configuration and outputs an Xcode project with a matching configuration and files.

- It utilizes Aspects in Bazel, an interface used to extract information about rules in Bazel.
- Rule metadata is mapped to a higher level representation compatible with Xcode, `XcodeTarget`. 
- `XcodeTarget`s are then translated to Xcode data structures
- XcodeGen is responsible for writing out the `.xcodeproj` file.

### Generation Performance
Project generation is in the critical path of development and needs to run quite often, so it's important that project generation is fast as possible. XCHammer employs multiple tactics to make generation fast including:

- partitioning the workspace into multiple projects
- incremental generation - generating only the projects it needs.
- parallel generation of projects - it generates an entire project on a core.
- lazy memoization of the `XcodeTarget` layer

The Pinterest workspace consists of 4 projects to enable incremental generation and produce a better experience. The workspace consists of a project for apps and extensions, a project for third party code and CocoaPods, a project for core subsystems, and a project for integration tests.

## Reproducing a Bazel build in Xcode

XCHammer produces Xcode projects that represent a Bazel build, with the intention that the user can build primarily with Xcode.

Since Xcode relies on the project configuration for semantic IDE features, like code completion and diagnostics, correctly setting up the Xcode configuration is a requirement. From the developers perspective, the Xcode build is functionally equivalent to the Bazel one: optimizations, files, errors, and warnings are identical.

### Diagnostics
The conversion from Bazel to Xcode is challenging. For example, compiler diagnostics are highly configurable and constantly evolving.  It’s difficult to produce the exact same compiler invocation in Xcode, as there is no way to disable all diagnostic options. Therefore, XCConfigs are lowest common denominator and the source of truth for diagnostic options. Internally, a dummy Xcode project is used to generate compiler flags based on XCConfigs. Via a custom `CROSSTOOL`, all default diagnostic flags are removed.

### Default Configuration
XCHammer generates projects based a default configuration to keep the project as simple as possible. More intricate build configurations exist exclusively in Bazel.

### Acknowledgements

XCHammer stands on the shoulders of community projects. It utilizes the Tulsi generator framework to extract metadata from Bazel and XcodeGen to write out projects. Special thanks to folks over at Bazel and, XcodeGen, for creating these projects!

### Conclusion

XCHammer is an instrumental part of Pinterest's iOS developer toolchain. Checkout [Github](https://github.com/pinterest/xchammer) page for more info!
