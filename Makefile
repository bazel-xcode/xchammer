.PHONY : test workspace archive unsafe_install install compile_commands debug run run_force test build

ASSETDIR=XCHammerAssets
ASPECTDIR=tulsi-aspects
PRODUCT=XCHammer

PREFIX := /usr/local
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

workspace:
	swift package generate-xcodeproj
	# Export the tulsi workspace to PWD. We need this for
	# Xcode, because there is no way to correctly install
	# resources.
	./export_tulsi_aspect_dir.sh ${PWD}/tulsi-aspects

clean:
	rm -rf tmp_build_dir
	xcrun swift package clean

# Create an archive package with a release binary and all bundle resources
archive: CONFIG = release
archive: build-release
	mkdir -p tmp_build_dir/$(PRODUCT)
	ditto .build/$(CONFIG)/$(PRODUCT) tmp_build_dir/$(PRODUCT)/
	./export_tulsi_aspect_dir.sh ${PWD}/$(ASPECTDIR)
	# Copy bundle resources
	ditto .build/$(CONFIG)/$(ASSETDIR) tmp_build_dir/$(PRODUCT)/$(ASSETDIR)
	ditto .build/$(CONFIG)/$(ASPECTDIR) tmp_build_dir/$(PRODUCT)/$(ASPECTDIR)

# Install but don't do a clean
unsafe_install: archive
	mkdir -p $(PREFIX)/bin
	ditto tmp_build_dir/$(PRODUCT) $(PREFIX)/bin/

install: clean archive
	mkdir -p $(PREFIX)/bin
	ditto tmp_build_dir/$(PRODUCT) $(PREFIX)/bin/

uninstall:
	rm -rf $(PREFIX)/bin/$(PRODUCT)
	rm -rf $(PREFIX)/bin/$(ASPECTDIR)
	rm -rf $(PREFIX)/bin/$(ASSETDIR)

compile_commands:
	./Scripts/generate_compilation_database.sh

build-debug: CONFIG = debug
build-debug: SWIFTBFLAGS = --configuration $(CONFIG)
build-debug: build-impl

build-release: CONFIG = release
build-release: SWIFTBFLAGS = --configuration $(CONFIG) -Xswiftc -static-stdlib
build-release: build-impl

build-impl:
	swift build $(SWIFTBFLAGS)
	# Install bundle resources
	ditto $(ASPECTDIR) .build/$(CONFIG)/$(ASPECTDIR)
	ditto $(ASSETDIR) .build/$(CONFIG)/$(ASSETDIR)

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

# Run a debug build of XCHammer
# Development hack: don't actually install, just symlink the debug build
run: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate $(ROOT_DIR)/sample/UrlGet/XCHammer.yaml --workspace_root $(ROOT_DIR)/sample/UrlGet

run_force: build
	$(ROOT_DIR)/.build/debug/$(PRODUCT) generate $(ROOT_DIR)/sample/UrlGet/XCHammer.yaml --workspace_root $(ROOT_DIR)/sample/UrlGet --force

