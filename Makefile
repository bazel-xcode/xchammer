.PHONY : test workspace archive unsafe_install install compile_commands debug run run_force test build

ASSETDIR=XCHammerAssets
ASPECTDIR=tulsi-aspects
PRODUCT=XCHammer

PREFIX := /usr/local
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

aspects:
	# Export the tulsi workspace to PWD. We need this for
	# Xcode, because there is no way to correctly install
	# resources.
	# Note that the build process always exports from this directory to the
	# bundle
	./export_tulsi_aspect_dir.sh ${PWD}/tulsi-aspects

# Copy the tulsi-aspects and XCHammerAssets adjacent to the Xcode build
# directory to allow loading of resources, since we can't express this in SPM or
# Xcode generated SPM
# This is the format of the XCHammer package
workspace: aspects
	swift package generate-xcodeproj
	$(eval BUILD_DIR=$(shell xcodebuild -showBuildSettings \
			-project XCHammer.xcodeproj/ \
			-scheme XCHammer \
			|  awk '$$1 == "BUILD_DIR" { print $$3 }'))
	@mkdir -p "$(BUILD_DIR)"
	@ditto "$(ASPECTDIR)" "$(BUILD_DIR)/Debug/"
	@ditto "$(ASSETDIR)" "$(BUILD_DIR)/Debug/$(ASSETDIR)"
	@ditto "$(ASPECTDIR)" "$(BUILD_DIR)/Release/"
	@ditto "$(ASSETDIR)" "$(BUILD_DIR)/Release/$(ASSETDIR)"

clean:
	rm -rf tmp_build_dir
	xcrun swift package clean

# Create an archive package with a release binary and all bundle resources
# Note, that this does not self update.
archive: CONFIG = release
archive: build-release aspects
	rm -rf tmp_build_dir
	mkdir -p tmp_build_dir/$(PRODUCT)
	ditto .build/$(CONFIG)/$(PRODUCT) tmp_build_dir/$(PRODUCT)/
	./export_tulsi_aspect_dir.sh ${PWD}/$(ASPECTDIR)
	# Copy bundle resources
	ditto $(ASPECTDIR) tmp_build_dir/$(PRODUCT)/
	ditto .build/$(CONFIG)/$(ASSETDIR) tmp_build_dir/$(PRODUCT)/$(ASSETDIR)

# Install but don't do a clean
unsafe_install: archive
	mkdir -p $(PREFIX)/bin
	ditto tmp_build_dir/$(PRODUCT) $(PREFIX)/bin/

install: clean archive
	mkdir -p $(PREFIX)/bin
	ditto tmp_build_dir/$(PRODUCT) $(PREFIX)/bin/

uninstall:
	rm -rf $(PREFIX)/bin/*

.PHONY: compile_commands.json
# https://github.com/swift-vim/SwiftPackageManager.vim
compile_commands.json:
	swift package clean
	which spm-vim
	swift build --build-tests \
                -Xswiftc -parseable-output | tee .build/commands_build.log
	cat .build/commands_build.log | spm-vim compile_commands


build-debug: CONFIG = debug
build-debug: SWIFTBFLAGS = -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13 --configuration $(CONFIG)
build-debug: build-impl

build-release: CONFIG = release
build-release: SWIFTBFLAGS = -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13 --configuration $(CONFIG) -Xswiftc -static-stdlib
build-release: build-impl

build-impl:
	swift build $(SWIFTBFLAGS) | tee .build/last_build.log
	# Install bundle resources
	ditto $(ASSETDIR) .build/$(CONFIG)/$(ASSETDIR)
	# Install Tulsi resources
	# Tulsi utilizes NSBundle heavily. All assets need to exist at the root of
	# this directory in order for NSBundle and Tulsi's searching logic to work
	# in the context of our custom release package.
	ditto $(ASPECTDIR) .build/$(CONFIG)/

build: build-debug
	@ln -sf $(PWD)/.build/debug sample/UrlGet/tools/XCHammer

test:
	$(ROOT_DIR)/IntegrationTests/run_tests.sh

debug: build
	# Launches LLDB with XCHammer
	# Example usage ( set a breakpoint at a line )
	# The run
	# br set -f Spec.swift -l 334
	# r
	lldb $(ROOT_DIR)/.build/debug/XCHammer

GENERATE_BAZEL_TARGETS_FLAG=--generate_bazel_targets


# Run a debug build of XCHammer
# Development hack: don't actually install, just symlink the debug build
run: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate \
	    $(ROOT_DIR)/sample/UrlGet/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/UrlGet \
	    --bazel $(ROOT_DIR)/sample/UrlGet/tools/bazelwrapper \
	    $(GENERATE_BAZEL_TARGETS_FLAG)

run_force: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate \
	    $(ROOT_DIR)/sample/UrlGet/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/UrlGet \
	    --bazel $(ROOT_DIR)/sample/UrlGet/tools/bazelwrapper \
	    $(GENERATE_BAZEL_TARGETS_FLAG) \
	    --force


ci: test
