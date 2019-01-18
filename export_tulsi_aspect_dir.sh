EXPORT_DIR=$1

if [[ $(basename $EXPORT_DIR) != "tulsi-aspects" ]]; then
	echo "Path must end in tulsi-aspects"
	exit 0
fi

# Fetch xchammer
tools/bazelwrapper fetch xchammer

TULSI_DIR="$(tools/bazelwrapper info output_base)/external/xchammer-Tulsi"

rm -rf $EXPORT_DIR
mkdir $EXPORT_DIR

mkdir $EXPORT_DIR/tulsi/
ditto $TULSI_DIR/src/TulsiGenerator/Bazel/* $EXPORT_DIR/tulsi/

ditto $TULSI_DIR/src/TulsiGenerator/Scripts/* $EXPORT_DIR

