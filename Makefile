.PHONY : test workspace archive unsafe_install install compile_commands debug run run_force test build

ASSETDIR=XCHammerAssets
ASPECTDIR=tulsi-aspects
PRODUCT=XCHammer

PREFIX := /usr/local
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

aspects:
	swift package resolve
	# Export the tulsi workspace to PWD. We need this for
	# Xcode, because there is no way to correctly install
	# resources.
	# Note that the build process always exports from this directory to the
	# bundle
	./export_tulsi_aspect_dir.sh ${PWD}/$(ASPECTDIR)


# Make a SPM generated Xcode project.
#
# Copy the tulsi-aspects and XCHammerAssets adjacent to the Xcode build
# directory to allow loading of resources, since we can't express this in SPM
#
# Note: this is brittle and may not work as expected
workspace_spm: aspects
	swift package generate-xcodeproj
	$(eval BUILD_DIR=$(shell xcodebuild -showBuildSettings \
			-project XCHammer.xcodeproj/ \
			-scheme XCHammer \
			|  awk '$$1 == "BUILD_DIR" { print $$3 }'))
	@mkdir -p "$(BUILD_DIR)"
	@ditto "$(ASPECTDIR)" "$(BUILD_DIR)/Debug/TulsiGenerator.framework"
	@ditto "$(ASSETDIR)" "$(BUILD_DIR)/Debug/$(ASSETDIR)"
	@ditto "$(ASPECTDIR)" "$(BUILD_DIR)/Release/TulsiGenerator.framework"
	@ditto "$(ASSETDIR)" "$(BUILD_DIR)/Release/$(ASSETDIR)"


# Make an XCHammer XCHammer Xcode project.
#
# Note:
# - this is under development and doesn't fully work
# - incremental builds are currently not working with Bazel
# - run with `force` for development
workspace_xchammer: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate \
	    $(ROOT_DIR)/XCHammer.yaml \
	    --bazel $(ROOT_DIR)/tools/bazelwrapper \
	    --force

workspace: workspace_spm

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

install: archive
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

# Build impl doesn't build aspects because it is slow.
build: build-debug
	@ln -sf $(PWD)/.build/debug sample/UrlGet/tools/XCHammer

test: aspects
	SAMPLE=UrlGet $(ROOT_DIR)/IntegrationTests/run_tests.sh

debug: build
	# Launches LLDB with XCHammer
	# Example usage ( set a breakpoint at a line )
	# The run
	# br set -f Spec.swift -l 334
	# r
	lldb $(ROOT_DIR)/.build/debug/XCHammer


# XCHammer Samples
# A sample exemplifies important behavior in XCHammer
#
# Conventions:
# - in the directory sample i.e. sample/UrlGet
# - has an XCHammer.yaml
# - contains a project named after the dir i.e. UrlGet.xcodeproj
# - has bazel and non bazel targets that build.
# - has a bazelwrapper ( a shellscript that runs some bazel )
SAMPLE ?= UrlGet

# Run a debug build of XCHammer against a sample
# Development hack: don't actually install, just symlink the debug build
# See README for usage in a normal project
run: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate \
	    $(ROOT_DIR)/sample/$(SAMPLE)/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/$(SAMPLE) \
	    --bazel $(ROOT_DIR)/sample/$(SAMPLE)/tools/bazelwrapper

run_force: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate \
	    $(ROOT_DIR)/sample/$(SAMPLE)/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/$(SAMPLE) \
	    --bazel $(ROOT_DIR)/sample/$(SAMPLE)/tools/bazelwrapper \
	    --force

run_perf: build-release
	@[[ -d sample/Frankenstein/Vendor/rules_pods ]] \
		|| (echo "Run 'make' in sample/Frankenstein" && exit 1)
	$(ROOT_DIR)/.build/release/$(PRODUCT) generate \
	    $(ROOT_DIR)/sample/Frankenstein/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/Frankenstein \
	    --bazel $(ROOT_DIR)/sample/Frankenstein/tools/bazelwrapper \
	    --force

# Create golden files from samples.
# Expectations:
# - output is stable. i.e. things don't move around
# - output is reproducible across machines
# TODO: Port Frankenstein to external PodToBUILD before adding it as a
# goldmaster
goldmaster:
	@rm -rf IntegrationTests/Goldmaster
	@mkdir -p IntegrationTests/Goldmaster
	@for S in $$(ls sample); do \
		[[ $$S != "Frankenstein" ]] || continue; \
		SAMPLE=$$S make run_force || exit 1; \
		echo "Making goldmaster for $$S"; \
		MASTER=IntegrationTests/Goldmaster/$$S.xcodeproj; \
		mkdir -p $$MASTER; \
		ditto sample/$$S/$$S.xcodeproj/project.pbxproj $$MASTER/project.pbxproj; \
		sed -i '' 's,$(PWD),__PWD__,g' $$MASTER/project.pbxproj; \
		sed -i '' 's,XCHAMMER.*,,g' $$MASTER/project.pbxproj; \
		ditto sample/$$S/$$S.xcodeproj/xcshareddata/xcschemes $$MASTER/xcshareddata/xcschemes; \
	done

run_swift: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate \
	    $(ROOT_DIR)/sample/Tailor/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/Tailor \
	    --bazel $(ROOT_DIR)/sample/Tailor/tools/bazelwrapper \
	    --force

# On the CI we always load the deps
run_perf_ci:
	$(MAKE) -C sample/Frankenstein
	$(MAKE) run_perf

ci: test run_perf_ci run_swift

format:
	$(ROOT_DIR)/tools/bazelwrapper run buildifier

