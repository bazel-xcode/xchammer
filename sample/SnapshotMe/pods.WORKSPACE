new_pod_repository(
    name = "iOSSnapshotTestCase",
    owner = "@ios-cx",
    url = "https://github.com/uber/ios-snapshot-test-case/archive/4.0.0.zip",
    inhibit_warnings = True,
    generate_module_map = False,
    enable_modules = False,
    podspec_url = "Vendor/iOSSnapshotTestCase/iOSSnapshotTestCase.podspec",
    install_script = """
      /usr/bin/sed -i "" "s,build,__build,g" .gitignore
      # FIXME: _hdrs for swift targets
      __INIT_REPO__
    """
)
