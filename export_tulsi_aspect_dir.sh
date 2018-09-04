EXPORT_DIR=$1

if [[ $(basename $EXPORT_DIR) != "tulsi-aspects" ]]; then
	echo "Path must end in tulsi-aspects"
	exit 0
fi
echo "Working around Swift Package managers ability to handle Tulsi..."

ROOT_DIR=$PWD
TULSI=$(ls -t -d $PWD/.build/checkouts/Tulsi.git-* | head -n1)

cd $TULSI
echo "Building Tulsi resources"
xcodebuild build -scheme TulsiApp -derivedDataPath $PWD/tulsi_build -project src/Tulsi.xcodeproj/ -configuration Release

echo "Exporting resources to $1"
# Export resources
rm -rf $EXPORT_DIR

cp -r tulsi_build/Build/Products/Release/TulsiGenerator.framework/Resources/ $EXPORT_DIR
