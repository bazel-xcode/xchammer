EXPORT_DIR=$1

if [[ $(basename $EXPORT_DIR) != "tulsi-aspects" ]]; then
	echo "Path must end in tulsi-aspects"
	exit 0
fi
echo "Working around Swift Package managers ability to handle Tulsi..."

ROOT_DIR=$PWD
TULSI=$(ls -t -d $PWD/.build/checkouts/Tulsi.git-* | head -n1)

cd $TULSI
echo "Building Tulsi"
xcodebuild -target TulsiGenerator -project src/Tulsi.xcodeproj/

echo "Exporting resources to $1"
# Export resources
rm -rf $EXPORT_DIR
OUT_DIR=src/build/Release/TulsiGenerator.framework/Resources/

if [[ $(command -v realpath) ]]; then
    cp -r $(realpath src/build/Release/TulsiGenerator.framework/Resources) $EXPORT_DIR
else
    cp -r src/build/Release/TulsiGenerator.framework/Resources $EXPORT_DIR
fi
