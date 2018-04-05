# This file is governed by XCHammer
set -e

if [[ "0.1.5" != "/Users/jerry/Projects/xchammer-github/.build/debug/XCHammer --version" ]]; then 
    echo "warning: XCHammer version mismatch"
fi

if [[ $ACTION == "clean" ]]; then
    exit 0
fi

PREV_STAT=`stat -f %c "/Users/jerry/Projects/xchammer-github/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/genStatus"`
/Users/jerry/Projects/xchammer-github/.build/debug/XCHammer generate /Users/jerry/Projects/xchammer-github/sample/UrlGet/XCHammer.yaml --workspace_root /Users/jerry/Projects/xchammer-github/sample/UrlGet --bazel /Users/jerry/.bazelenv/versions/0.12.0rc1/bin/bazel
STAT=`stat -f %c "/Users/jerry/Projects/xchammer-github/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/genStatus"`
if [[ "$PREV_STAT" != "$STAT" ]]; then
    echo "error: Xcode project was out-of-date so we updated it for you! Please build again."
    exit 1
fi