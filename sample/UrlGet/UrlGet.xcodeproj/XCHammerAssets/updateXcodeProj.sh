# This file is governed by XCHammer
set -e

if [[ "0.1.7" != "/Users/mzuccarino/code/mikezucc/xchammer/.build/debug/XCHammer --version" ]]; then 
    echo "warning: XCHammer version mismatch"
fi

if [[ $ACTION == "clean" ]]; then
    exit 0
fi

PREV_STAT=`/usr/bin/stat -f %c "/Users/mzuccarino/code/mikezucc/xchammer/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/genStatus"`
/Users/mzuccarino/code/mikezucc/xchammer/.build/debug/XCHammer generate /Users/mzuccarino/code/mikezucc/xchammer/sample/UrlGet/XCHammer.yaml --workspace_root /Users/mzuccarino/code/mikezucc/xchammer/sample/UrlGet --bazel /Users/mzuccarino/code/mikezucc/xchammer/sample/UrlGet/tools/bazelwrapper --generate_bazel_targets
STAT=`/usr/bin/stat -f %c "/Users/mzuccarino/code/mikezucc/xchammer/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/genStatus"`
if [[ "$PREV_STAT" != "$STAT" ]]; then
    echo "error: Xcode project was out-of-date so we updated it for you! Please build again."
    exit 1
fi