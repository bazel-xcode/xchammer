# XCHammer

XCHammer makes a pure xcode project using a tulsi-configured bazel project.

See: [XcodeGen ProjectSpec Docs](https://github.com/yonaskolb/XcodeGen/blob/master/docs/ProjectSpec.md) for valid XcodeGen project structure

## Usage

```
./XCHammer project <workspaceRootPath> <outputProjectPath> <configPath> <bazelPath>
```

Will generate a project at the specified project path using the `config` at `configPath`. 

### Configuration Format

todo:(jerry)

For more information run

```
./XCHammer help
```

You can `help` specific commands, like:

```
./XCHammer help generate
```

as well.

## Development

Run:

```bash
swift package generate-xcodeproj
```

Edit to your hearts content!

## Code

`main.swift` hooks together all the pieces of the puzzle. This is a good place to start reading code. Check out the implementation of the `GenerateCommand` struct.

First we load the `RuleEntryMap` from aspects using TulsiGenerator. We also pull out enough information from Tulsi so that we can construct a Bazel query to capture any generated files the Xcode project may depend on. Eventually, we inject this bazel query into a legacy target in `XCHammer.emitProject`.

We convert the `RuleEntryMap` from Tulsi into a `Spec.Project`, a high-level representation of the xcodegen project spec yaml, within `XCHammer.emitProject`.

`XCHammer.emitProject` is where most of the work is done. Here we output all files necessary for the Xcode project. There are a few static assets (various scripts consumed during builds), a few simple dynamic assets (headers for BUILD files, etc), and, a high-level representation of the xcodegen project spec. This is later passed off to `XcodeGenKit` inside `main.swift` which produces the XcodeProject for us.

The bulk of the logic of `XCHammer` is conceptually a single pure function of type `(RuleEntryMap) -> [Spec.Target]`. Essentially, we create a `Spec.Target` for each of the Tulsi provided bazel targets (provided as `RuleEntry`s).

`makeTarget` within `RuleEntryExtensions` is the top-level function that runs for each target. Essentially, this file is littered with `extract*` functions that extract some slice of information from the bazel dependency graph for some specific target. Graph traversals use `TraversalTransitionPredicate`s to describe how to prune the traversals for depending on the information we need to extract.

In the end, we get a `Spec.Target`, then we run this procedure for all targets in the `RuleEntryMap` and get `[Spec.Target]`. We can inject the `[Spec.Target]` into the `Spec.Project` and then, finally, we hand it off to `XcodeGenKit`.

