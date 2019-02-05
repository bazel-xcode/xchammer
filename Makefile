.PHONY : test workspace archive unsafe_install install compile_commands debug run run_force test build build build-release

ASSETDIR=XCHammerAssets
ASPECTDIR=tulsi-aspects

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

ifeq ($(BAZEL_BUILD),true)
	PRODUCT=xchammer
	XCHAMMER_BIN_BASE=$(ROOT_DIR)/xchammer.app/Contents/MacOS
else
	PRODUCT=XCHammer
	XCHAMMER_BIN_BASE=$(PWD)/.build/debug
endif

XCHAMMER_BIN := $(XCHAMMER_BIN_BASE)/$(PRODUCT)

PREFIX := /usr/local

aspects:
ifneq ($(BAZEL_BUILD),true)
	# Export the tulsi workspace to PWD. We need this for
	# Xcode, because there is no way to correctly install
	# resources.
	# Note that the build process always exports from this directory to the
	# bundle
	./export_tulsi_aspect_dir.sh ${PWD}/$(ASPECTDIR)
endif

generate_xcodeproj:
	swift package generate-xcodeproj

# Make a SPM generated Xcode project.
#
# Copy the tulsi-aspects and XCHammerAssets adjacent to the Xcode build
# directory to allow loading of resources, since we can't express this in SPM
#
# Note: this is brittle and may not work as expected
workspace_spm: aspects generate_xcodeproj
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
# - the DSL is not fully integrated into XCHammer - this make target needs to
#   create the XCHammer.yaml out of band.
# - Currently gen times are out of band as well.
workspace_xchammer: build
	tools/bazelwrapper build :xchammer_config
	$(XCHAMMER_BIN) generate \
		bazel-genfiles/xchammer_config/XCHammer.json \
	    --bazel $(ROOT_DIR)/tools/bazelwrapper \
	    --force

workspace: workspace_spm

clean:
	rm -rf tmp_build_dir
	xcrun swift package clean
	$(ROOT_DIR)/tools/bazelwrapper clean

# Create an archive package with a release binary and all bundle resources
# Note, that this does not self update.
archive: CONFIG = release
archive: aspects build-release
	rm -rf tmp_build_dir
	mkdir -p tmp_build_dir/$(PRODUCT)
	ditto .build/$(CONFIG)/$(PRODUCT) tmp_build_dir/$(PRODUCT)/
	@# Copy bundle resources
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
build-debug: SWIFTBFLAGS = -Xswiftc -target \
	-Xswiftc x86_64-apple-macosx10.13 \
	--configuration $(CONFIG)
build-debug: BAZELFLAGS = --announce_rc \
	--spawn_strategy=standalone \
	--disk_cache=$(HOME)/Library/Caches/Bazel
build-debug: build-impl

build-release: CONFIG = release
build-release: SWIFTBFLAGS = -Xswiftc -target \
	-Xswiftc x86_64-apple-macosx10.13 \
	--configuration $(CONFIG) -Xswiftc -static-stdlib
build-release: BAZELFLAGS = --announce_rc \
	--compilation_mode opt \
	--spawn_strategy=standalone \
	--disk_cache=$(HOME)/Library/Caches/Bazel
build-release: build-impl

build-impl:
ifeq ($(BAZEL_BUILD),true)
	$(ROOT_DIR)/tools/bazelwrapper build \
		 $(BAZELFLAGS) xchammer
	@rm -rf $(ROOT_DIR)/xchammer.app
	@unzip -q $(ROOT_DIR)/bazel-bin/xchammer.zip
else
	@mkdir -p .build
	@swift build $(SWIFTBFLAGS) | tee .build/last_build.log
	# Install bundle resources
	@ditto $(ASSETDIR) .build/$(CONFIG)/$(ASSETDIR)
	# Install Tulsi resources
	# Tulsi utilizes NSBundle heavily. All assets need to exist at the root of
	# this directory in order for NSBundle and Tulsi's searching logic to work
	# in the context of our custom release package.
	@ditto $(ASPECTDIR) .build/$(CONFIG)/
endif

build: aspects build-debug
	@# Hacks for SPM build
	@rm -rf .build/debug/debug || true # This creates a cycle
	@[[ "$(SAMPLE)" ]] && \
	    (ditto $(PWD)/.build/debug sample/$(SAMPLE)/tools/XCHammer || true)

test: build
	XCHAMMER_BIN=$(XCHAMMER_BIN) SAMPLE=UrlGet $(ROOT_DIR)/IntegrationTests/run_tests.sh

debug: build
	# Launches LLDB with XCHammer
	# Example usage ( set a breakpoint at a line )
	# The run
	# br set -f Spec.swift -l 334
	# r
	lldb $(XCHAMMER_BIN)


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
	$(XCHAMMER_BIN) generate \
	    $(ROOT_DIR)/sample/$(SAMPLE)/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/$(SAMPLE) \
	    --bazel $(ROOT_DIR)/sample/$(SAMPLE)/tools/bazelwrapper

# FIXME: add code to handle `xcworkspace` to `run`
run_workspace: build
	$(XCHAMMER_BIN) generate \
		$(ROOT_DIR)/sample/SnapshotMe/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/SnapshotMe \
	    --xcworkspace $(ROOT_DIR)/sample/SnapshotMe/SnapshotMe.xcworkspace \
	    --bazel $(ROOT_DIR)/sample/SnapshotMe/tools/bazelwrapper

run_force: build
	$(XCHAMMER_BIN) generate \
	    $(ROOT_DIR)/sample/$(SAMPLE)/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/$(SAMPLE) \
	    --bazel $(ROOT_DIR)/sample/$(SAMPLE)/tools/bazelwrapper \
	    --force

run_perf: build-release
	@[[ -d sample/Frankenstein/Vendor/rules_pods ]] \
		|| (echo "Run 'make' in sample/Frankenstein" && exit 1)
	$(XCHAMMER_BIN) generate \
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
	$(XCHAMMER_BIN) generate \
	    $(ROOT_DIR)/sample/Tailor/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/Tailor \
	    --bazel $(ROOT_DIR)/sample/Tailor/tools/bazelwrapper \
	    --force

# On the CI we always load the deps
run_perf_ci:
	rm -rf sample/Frankenstein/Vendor/rules_pods
	$(MAKE) -C sample/Frankenstein
	$(MAKE) run_perf

# On the CI - we stick a .bazelrc into the home directory to control
# how every single bazel build works. ( Any sample get's this )
bazelrc_home:
ifeq ($(BAZEL_BUILD),true)
	echo "build --disk_cache=$(HOME)/Library/Caches/Bazel \\" > ~/.bazelrc
	echo "     --spawn_strategy=standalone" >> ~/.bazelrc
endif

ci: clean bazelrc_home test run_perf_ci run_swift 

format:
	$(ROOT_DIR)/tools/bazelwrapper run buildifier

.PHONY:
xchammer_config:
	tools/bazelwrapper build xchammer_config
