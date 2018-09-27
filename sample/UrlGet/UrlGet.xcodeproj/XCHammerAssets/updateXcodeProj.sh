# This file is governed by XCHammer
set -e

if [[ "0.1.7" != "/Users/jerry/Projects/xchammer-github/.build/debug/XCHammer --version" ]]; then 
    echo "warning: XCHammer version mismatch"
fi

if [[ $ACTION == "clean" ]]; then
    exit 0
fi

PREV_STAT=`/usr/bin/stat -f %c "/Users/jerry/Projects/xchammer-github/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/genStatus"`
/Users/jerry/Projects/xchammer-github/.build/debug/XCHammer generate /Users/jerry/Projects/xchammer-github/sample/UrlGet/XCHammer.yaml --workspace_root /Users/jerry/Projects/xchammer-github/sample/UrlGet --bazel /Users/jerry/Projects/xchammer-github/sample/UrlGet/tools/bazelwrapper
STAT=`/usr/bin/stat -f %c "/Users/jerry/Projects/xchammer-github/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/genStatus"`
if [[ "$PREV_STAT" != "$STAT" ]]; then
    echo "error: Xcode project was out-of-date so we updated it for you! Please build again."
    exit 1
fi