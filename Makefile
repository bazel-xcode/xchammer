.PHONY : test workspace archive install compile_commands debug run run_force test build build build-release

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

PRODUCT := xchammer.app
XCHAMMER_APP := $(ROOT_DIR)/bazel-bin/xchammer_archive-root/xchammer.app
XCHAMMER_BIN := $(XCHAMMER_APP)/Contents/MacOS/XCHammer

PREFIX := /usr/local

# Make an XCHammer XCHammer Xcode project.
# Note: we manually build the XCHammer config here, consider better support to
# build the project DSL within XCHammer directly.
workspace: build
	@tools/bazelwrapper build :xchammer_config
	$(XCHAMMER_BIN) generate \
		bazel-bin/xchammer_config/XCHammer.json \
	    --bazel $(ROOT_DIR)/tools/bazelwrapper \
	    --force

workspace_v2:
	tools/bazelwrapper build $(BAZEL_OPTS) :workspace_v2 :xchammer_dev

clean:
	$(ROOT_DIR)/tools/bazelwrapper clean

archive: build-release

# Brew support
install: archive
	mkdir -p $(PREFIX)/bin
	ditto $(XCHAMMER_APP) $(PREFIX)/bin/$(PRODUCT)
	ln -s $(PREFIX)/bin/$(PRODUCT)/Contents/MacOS/xchammer $(PREFIX)/bin/xchammer

uninstall:
	unlink $(PREFIX)/bin/xchammer
	rm -rf $(PREFIX)/bin/$(PRODUCT)

# Note: this is used here to have a dynamic `home` variable, as its idomatic
# to put the cache here with macOS.
BAZEL_CACHE_OPTS=--repository_cache=$(HOME)/Library/Caches/Bazel \
	--disk_cache=$(HOME)/Library/Caches/Bazel

build-debug: BAZEL_OPTS=$(BAZEL_CACHE_OPTS)
build-debug: build-impl

build-release: BAZEL_OPTS=$(BAZEL_CACHE_OPTS) \
	--compilation_mode opt
build-release: build-impl

build-impl:
	$(ROOT_DIR)/tools/bazelwrapper build $(BAZEL_OPTS) :xchammer :xchammer_dist :xchammer_dev

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

run_perf: build-release
	@[[ -d sample/Frankenstein/Vendor/rules_pods ]] \
		|| (echo "Run 'make' in sample/Frankenstein" && exit 1)
	$(XCHAMMER_BIN) generate \
	    $(ROOT_DIR)/sample/Frankenstein/XCHammer.yaml \
	    --workspace_root $(ROOT_DIR)/sample/Frankenstein \
	    --bazel $(ROOT_DIR)/sample/Frankenstein/tools/bazelwrapper \
	    --force

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
	    tools/bazelwrapper build -s :XcodeBazel $(BAZEL_CACHE_OPTS)

# On the CI we always load the deps
run_perf_ci: build
	rm -rf sample/Frankenstein/Vendor/rules_pods
	$(MAKE) -C sample/Frankenstein
	$(MAKE) run_perf

# On the CI - we stick a .bazelrc into the home directory to control
# how every single bazel build works. ( Any sample get's this )
bazelrc_home:
	echo "build $(BAZEL_CACHE_OPTS) \\" > ~/.bazelrc
	echo "     --spawn_strategy=standalone" >> ~/.bazelrc

ci: bazelrc_home test run_perf_ci run_swift run_force_bazel goldmaster workspace

format:
	$(ROOT_DIR)/tools/bazelwrapper run buildifier

xchammer_config:
	tools/bazelwrapper build xchammer_config

update_bazelwrappers:
	find sample -name bazelwrapper -exec cp tools/bazelwrapper {} \;

