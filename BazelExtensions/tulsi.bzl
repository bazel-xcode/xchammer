# This makes it easier to load tulsi paths
# In the distribution artifact we need to:
# Include a binary build of XCHammer
load(
    "@xchammer_tulsi_aspects//:tulsi/tulsi_aspects_paths.bzl",
    _SwiftInfo = "SwiftInfo",
)

load(
    "@xchammer_tulsi_aspects//:tulsi/tulsi_aspects.bzl",
    _tulsi_sources_aspect = "tulsi_sources_aspect",
    _TulsiSourcesAspectInfo = "TulsiSourcesAspectInfo",
)

SwiftInfo = _SwiftInfo
tulsi_sources_aspect = _tulsi_sources_aspect
TulsiSourcesAspectInfo = _TulsiSourcesAspectInfo
