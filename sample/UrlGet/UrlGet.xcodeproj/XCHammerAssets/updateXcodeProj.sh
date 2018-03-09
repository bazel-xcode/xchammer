if [[ $ACTION == "clean" ]]; then
    exit 0
fi

CACHED_HASH=`cat "/Users/jerry/Projects/xchammer-github/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/depsHash"`
/Users/jerry/Projects/xchammer-github/.build/debug/XCHammer generate /Users/jerry/Projects/xchammer-github/sample/UrlGet/XCHammer.yaml --workspace_root /Users/jerry/Projects/xchammer-github/sample/UrlGet
HASH=`cat "/Users/jerry/Projects/xchammer-github/sample/UrlGet/UrlGet.xcodeproj/XCHammerAssets/depsHash"`
if [[ "$HASH" != "$CACHED_HASH" ]]; then
    echo "error: Xcode project was out-of-date so we updated it for you! Please build again."
    exit 1
fi