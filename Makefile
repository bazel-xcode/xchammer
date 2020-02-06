.PHONY : test workspace archive install compile_commands debug run run_force test build build build-release

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

PRODUCT := xchammer.app
XCHAMMER_BIN := $(ROOT_DIR)/$(PRODUCT)/Contents/MacOS/XCHammer

PREFIX := /usr/local

# Make an XCHammer XCHammer Xcode project.
# Note: we manually build the XCHammer config here, consider better support to
# build the project DSL within XCHammer directly.
workspace: build
	@tools/bazelwrapper build :xchammer_config
	$(XCHAMMER_BIN) generate \
		bazel-genfiles/xchammer_config/XCHammer.json \
	    --bazel $(ROOT_DIR)/tools/bazelwrapper \
	    --force

# Experimental Xcode project generator based on Bazel
workspace_v2:
	tools/bazelwrapper build -s :workspace_v2

clean:
	$(ROOT_DIR)/tools/bazelwrapper clean

archive: build-release

# Brew support
install: archive
	mkdir -p $(PREFIX)/bin
	ditto $(PRODUCT) $(PREFIX)/bin/$(PRODUCT)
	ln -s $(PREFIX)/bin/$(PRODUCT)/Contents/MacOS/xchammer $(PREFIX)/bin/xchammer

uninstall:
	unlink $(PREFIX)/bin/xchammer
	rm -rf $(PREFIX)/bin/$(PRODUCT)

.PHONY: compile_commands.json
# https://github.com/swift-vim/SwiftPackageManager.vim
compile_commands.json:
	swift package clean
	which spm-vim
	swift build --build-tests \
                -Xswiftc -parseable-output | tee .build/commands_build.log
	cat .build/commands_build.log | spm-vim compile_commands


build-debug: BAZELFLAGS = --announce_rc \
	--disk_cache=$(HOME)/Library/Caches/Bazel
build-debug: build-impl

build-release: BAZELFLAGS = --announce_rc \
	--compilation_mode opt \
	--disk_cache=$(HOME)/Library/Caches/Bazel
build-release: build-impl

build-release-no-cache: BAZELFLAGS = --announce_rc \
	--compilation_mode opt \
	--disk_cache=$(HOME)/Library/Caches/Bazel
build-release-no-cache: build-impl

build-impl:
	$(ROOT_DIR)/tools/bazelwrapper build \
		 $(BAZELFLAGS) xchammer
	@rm -rf $(ROOT_DIR)/xchammer.app
	@unzip -q $(ROOT_DIR)/bazel-bin/xchammer.zip

build: build-debug

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

run_perf: build-release-no-cache
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
clean_goldmaster:
	@rm -rf IntegrationTests/Goldmaster
	@mkdir -p IntegrationTests/Goldmaster

goldmaster_cli:
	@for S in $$(ls sample); do \
		[[ $$S != "Frankenstein" ]] || continue; \
		[[ $$S != "SnapshotMe" ]] || continue; \
		SAMPLE=$$S make run_force || exit 1; \
		echo "Making goldmaster for $$S"; \
		MASTER=IntegrationTests/Goldmaster/$$S/$$S.xcodeproj; \
		mkdir -p $$MASTER; \
		ditto sample/$$S/$$S.xcodeproj/project.pbxproj $$MASTER/project.pbxproj; \
		sed -i '' 's,$(PWD),__PWD__,g' $$MASTER/project.pbxproj; \
		sed -i '' 's,XCHAMMER.*,,g' $$MASTER/project.pbxproj; \
		ditto sample/$$S/$$S.xcodeproj/xcshareddata/xcschemes $$MASTER/xcshareddata/xcschemes; \
		find IntegrationTests/Goldmaster/$$S/ -name *.xcscheme -exec sed -i '' 's,TEMP.*,",g' {} \; ; \
	done

goldmaster_bazel:
	@for S in $$(ls sample); do \
		[[ $$S != "Frankenstein" ]] || continue; \
		SAMPLE=$$S make run_force_bazel || exit 1; \
		echo "Making goldmaster for $$S"; \
		MASTER=IntegrationTests/Goldmaster/$$S/XcodeBazel.xcodeproj; \
		mkdir -p $$MASTER; \
		ditto sample/$$S/XcodeBazel.xcodeproj/project.pbxproj $$MASTER/project.pbxproj; \
		sed -i '' 's,$(PWD),__PWD__,g' $$MASTER/project.pbxproj; \
		sed -i '' 's,XCHAMMER.*,,g' $$MASTER/project.pbxproj; \
		ditto sample/$$S/XcodeBazel.xcodeproj/xcshareddata/xcschemes $$MASTER/xcshareddata/xcschemes; \
	done

goldmaster: clean_goldmaster goldmaster_bazel goldmaster_cli

run_swift: build
	$(XCHAMMER_BIN) generate \
	    $(ROOT_DIR)/sample/Tailor/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/Tailor \
	    --bazel $(ROOT_DIR)/sample/Tailor/tools/bazelwrapper \
	    --force

# TODO:
# - currently the Bazel Xcode projects require defining xchammer_resources
# in the workspace. This needs to be resolved ( ideally moved to defining this
# as @xchammer as a bianry release in the WORKSPACE )
# - there seems to be an issue without running without standalone
run_force_bazel: build
	cd sample/$(SAMPLE)/ && \
	 tools/bazelwrapper clean  && \
	    tools/bazelwrapper build -s :XcodeBazel --spawn_strategy=standalone

# On the CI we always load the deps
run_perf_ci:
	rm -rf sample/Frankenstein/Vendor/rules_pods
	$(MAKE) -C sample/Frankenstein
	$(MAKE) run_perf

# On the CI - we stick a .bazelrc into the home directory to control
# how every single bazel build works. ( Any sample get's this )
bazelrc_home:
	echo "build --disk_cache=$(HOME)/Library/Caches/Bazel \\" > ~/.bazelrc
	echo "     --spawn_strategy=standalone" >> ~/.bazelrc

ci: bazelrc_home test run_perf_ci run_swift goldmaster

format:
	$(ROOT_DIR)/tools/bazelwrapper run buildifier

.PHONY:
xchammer_config:
	tools/bazelwrapper build xchammer_config

update_bazelwrappers:
	find sample -name bazelwrapper -exec cp tools/bazelwrapper {} \;

