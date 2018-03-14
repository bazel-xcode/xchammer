# This file is governed by XCHammer
if [[ $ACTION == "clean" ]]; then
    exit 0
fi

PREV_STAT=`stat -f %c "$0"`
/Users/jerry/Projects/xchammer-github/.build/debug/XCHammer generate /Users/jerry/Projects/xchammer-github/sample/UrlGet/XCHammer.yaml --workspace_root /Users/jerry/Projects/xchammer-github/sample/UrlGet
STAT=`stat -f %c "$0"`
if [[ "$PREV_STAT" != "$STAT" ]]; then
    echo "error: Xcode project was out-of-date so we updated it for you! Please build again."
    exit 1
fi