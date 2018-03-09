# This program updates compile_commands.json for XCHammer
# based on the Xcode build.
# Make sure to run it when you add/remove files!

echo "Updating workspace.."
make workspace

echo "Installing Schemes.."
ditto Scripts/XCHammerShareData/ XCHammer.xcodeproj/xcshareddata/

which XCCompilationDB
if [[ $? != 0 ]]; then
    echo "Install XcodeCompilationDatabase"
    exit 1
fi

echo "Building for comp database"
xcodebuild clean build -scheme XCHammerCompDB

