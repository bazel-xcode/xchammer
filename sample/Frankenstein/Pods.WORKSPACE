new_pod_repository(
  name = "boost-for-react-native",
  url = 'https://github.com/react-native-community/boost-for-react-native/archive/v1.63.0-0.zip',
  # This podspec isn't included in the http archives of boost.
  podspec_url = 'Vendor/PodSpecs/boost-for-react-native-1.63.0-0/boost-for-react-native.podspec',
  generate_module_map = False,
  install_script = """
    __INIT_REPO__
    # TODO: We need to add the ability to not generate this dir.
    rm -rf pod_support/Headers/Public/boost
  """,
)

new_pod_repository(
  name = "Folly",
  podspec_url = "Vendor/PodSpecs/react-0.57/third-party-podspecs/Folly.podspec",
  url = "https://github.com/facebook/folly/archive/v2016.09.26.00.zip",
  # header_visibility = "everything",
  generate_module_map = False
)

new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.5.zip',
  podspec_url = 'Vendor/PodSpecs/react-0.57/third-party-podspecs/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
  """,

  generate_module_map = False
)

new_pod_repository(
  name = "glog",
  url = 'https://github.com/google/glog/archive/v0.3.4.zip',
  podspec_url = 'Vendor/PodSpecs/react-0.57/third-party-podspecs/GLog.podspec',
  install_script = """
    # prepare_command
  	sh ../PodSpecs/glog-0.3.4/ios-configure-glog.sh || exit 1
  	__INIT_REPO__
  """,
  generate_module_map = False
)

# LEAVEME: Prior hacks for podspecs
# - Copy over third-party-podspecs to Vendor/Podspecs
# - Comment out busted prepare commands
new_pod_repository(
  name = "React",
  owner = "@schneider",
  url = 'https://github.com/facebook/react-native/archive/v0.57.0.zip',
  user_options = [
    # TODO: If Xcode is compiling CppLike with this standard, P2B should too.
    "jsinspector.copts += -std=c++14",
  ],

  # Module map doesn't work because it seems to be expecting the folly library
  generate_module_map = False,
  inhibit_warnings = True,

  # This is a workaround for a bug and warning emitted in `ObjcLibrary`
  # where we include non propagated headers in headers.
  header_visibility = "everything"
)

# WARNING: the version of react-native here doesn't match up with yoga.
new_pod_repository(
  name = "Yoga",
  owner = "@schneider",
  url = 'https://github.com/facebook/react-native/archive/v0.55.4.zip',
  strip_prefix = 'react-native-0.55.4/ReactCommon/yoga',
  install_script = """
    # We need to fix the package parameter here (even though we don't use in pod2build)
    # because the evaluation of the podspec in Ruby will fail. The package parameter
    # points to a JSON.parse of a file outside the yoga sandbox.
    /usr/bin/sed -i "" "s,^package.*,package = { 'version' => '0.46.3' },g" Yoga.podspec

    
    # The canonical version of Yoga uses the Podspec.name, 'Yoga'
    # React uses the name of 'yoga'. To use this with Texture, we need to
    # uppercase the name. This is an issue with React <-> Texture integration in
    # Pods.
    /usr/bin/sed -i "" "s,spec.module_name.*yoga,spec.module_name = 'Yoga,g" Yoga.podspec
    __INIT_REPO__
  """,

  generate_module_map = False
)
