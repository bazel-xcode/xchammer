#!/bin/bash

# Import the last updated index-store. This code assumes that we're writing a
# single index
INDEX_STORE=$(find $SRCROOT/bazel-out/ -name index-store -exec ls -ratd "{}" +;)

# This index import must be on the path
if [[ "$(which index-import)" ]]; then
    # This assumes we've added the index-store in BINDIR
    # copts = ["-index-store-path", "$(GENDIR)/index-store"],
    EXEC_ROOT="$(dirname $(readlink $SRCROOT/bazel-out))"
    DERIVEDDATA="$(dirname $(dirname $BUILD_ROOT))"

    echo "$(date) importing index" |
        tee -a $DERIVEDDATA/Logs/index-import.log
    # Loads index-import on path
    # TODO: produce binary builds and then bazel run index-import
    time index-import \
        -remap "$EXEC_ROOT=$SRCROOT" \
        $INDEX_STORE $DERIVEDDATA/Index/DataStore 2>&1 | \
        tee -a $DERIVEDDATA/Logs/index-import.log
fi
