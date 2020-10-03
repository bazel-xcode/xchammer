#!/bin/bash

if [[ "$CONFIGURATION" == "Release" ]]; then
    COMPILATION_MODE="opt"
elif [[ "$CONFIGURATION" == "Profile" ]]; then
    COMPILATION_MODE="opt"
else
    COMPILATION_MODE="dbg"
fi

export SPAWN_OPTS="--compilation_mode=$COMPILATION_MODE"
exec __BAZEL_COMMAND__
