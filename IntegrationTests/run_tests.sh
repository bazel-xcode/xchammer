#!/bin/bash
# Tests and Test runner.
# This program encompasses a sandboxed integration system that:
# - Builds and Runs XCHammer in Debug mode.
# - Invokes XCHammer to smoke test basic features.
# - Is sandboxed from the suite perspective.
#  ( We don't run each test in a sandbox but the suite is )
# sandbox right now.
# Additionally, it includes the actual test methods.

ROOT_DIR=$PWD
PRODUCT="XCHammer"

SANDBOX="$ROOT_DIR/IntegrationTests/Sandbox"

# We download and install bazel if its missing
BAZEL=($SANDBOX/UrlGet/tools/bazelwrapper)


TEST_PROJ="$SANDBOX/UrlGet/UrlGet.xcodeproj"
TEST_NEW_IMPL_FILE="$SANDBOX/UrlGet/ios-app/UrlGet/XCHammerIntegrationTestFile.m"

function assertExitCode() {
    if [[ $? != 0 ]]; then
        echo "❌  test_failed: $1"
        exit 1
    fi
    echo "✅  test_passed: $1"
}

# Test Methods: 

function testBuild() {
    echo "Testing generate and build with Xcode"
    $ROOT_DIR/.build/debug/$PRODUCT generate $SANDBOX/UrlGet/XCHammer.yaml --bazel $BAZEL
    xcodebuild -scheme ios-app -project $TEST_PROJ -sdk iphonesimulator
    assertExitCode "Xcode built successfully"
}

function testBazelBuild() {
    $ROOT_DIR/.build/debug/$PRODUCT generate $SANDBOX/UrlGet/XCHammer.yaml --bazel $BAZEL --force
    xcodebuild -scheme ios-app-Bazel -project $TEST_PROJ -sdk iphonesimulator
    assertExitCode "Xcode built bazel targets successfully"
}

function testNooping() {
    echo "Testing noop generation"
    $ROOT_DIR/.build/debug/$PRODUCT generate $SANDBOX/UrlGet/XCHammer.yaml --bazel $BAZEL
    RESULT=`$ROOT_DIR/.build/debug/$PRODUCT generate $SANDBOX/UrlGet/XCHammer.yaml --bazel $BAZEL`

    # We print Skipping update when we noop
    echo $RESULT | grep "Skipping"
    assertExitCode "Noop generation"
}

# Create a new file, and make sure Xcode is doing a build with that file
function testGenerateWhileBuilding() {
    $ROOT_DIR/.build/debug/$PRODUCT generate $SANDBOX/UrlGet/XCHammer.yaml --bazel $BAZEL

    touch $TEST_NEW_IMPL_FILE

    echo "Test file info `file $TEST_NEW_IMPL_FILE`"

    xcodebuild clean -project $TEST_PROJ
    # We intentionally fail xcodebuild here
    set +e
    RESULT=`xcodebuild -scheme ios-app -project $TEST_PROJ -sdk iphonesimulator`
    set -e

    # Search for Xcode's failure of `UpdateXcodeProject`
    echo $RESULT | grep "ExternalBuildToolExecution UpdateXcodeProject"
    assertExitCode "Xcode build should fail the first time"

    # Make sure the app was compiled with the new file
    RESULT=`xcodebuild -scheme ios-app -project $TEST_PROJ -sdk iphonesimulator`
    echo $RESULT | grep $(basename $TEST_NEW_IMPL_FILE)
    assertExitCode "Xcode build with new file"
}

# Setup and execution
function preflightEnv() {
    set -e

    # Bootstrap the sandbox. We hydrate the sandbox with the sample
    # program to prevent polluting the sample
    mkdir -p $SANDBOX
    ditto $ROOT_DIR/sample/UrlGet $SANDBOX/UrlGet
    rm -rf $SANDBOX/UrlGet/UrlGet.xcodeproj

    cd $SANDBOX/UrlGet;  

    echo "Checking bazel"
    $BAZEL info 
    set +e
}

# This function runs after the test suite is done.
function testsDidFinish() {
    echo "tests_completed with status $?"
    rm -rf $SANDBOX
}

# Run the tests. Order should not matter!
function runTests() {
    set -e
    testBuild
    testBazelBuild
    testGenerateWhileBuilding
    testNooping
}

## Execution

echo "Running tests"

# Do a debug build
make build

trap testsDidFinish EXIT
preflightEnv
runTests
echo "Ran tests"

