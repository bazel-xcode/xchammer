set -e
# Unzip the build service app so we don't ship it as a zip file
ARCHIVE_ROOT="$1"
ZIP="$ARCHIVE_ROOT/xchammer.app/Contents/Resources/BazelBuildService.zip"
TARGET="$ARCHIVE_ROOT/xchammer.app/Contents/Resources/BazelBuildService.app"
unzip -q "$ZIP"
mv BazelBuildService.app $TARGET
rm -rf "$ZIP"
