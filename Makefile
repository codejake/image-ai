PRODUCT := image-ai
CONFIGURATION := release

DEVELOPER_DIR ?= /Applications/Xcode-beta.app/Contents/Developer
PREFIX ?= $(HOME)
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=

.PHONY: all release install test format lint check clean

all: release

release:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift build \
		-c "$(CONFIGURATION)" \
		--product "$(PRODUCT)"

install: release
	@BIN_PATH="$$(DEVELOPER_DIR="$(DEVELOPER_DIR)" \
		xcrun swift build -c "$(CONFIGURATION)" --show-bin-path)"; \
	INSTALL_DIR="$(DESTDIR)$(BINDIR)"; \
	mkdir -p "$$INSTALL_DIR"; \
	install -m 755 "$$BIN_PATH/$(PRODUCT)" "$$INSTALL_DIR/$(PRODUCT)"; \
	echo "Installed $(PRODUCT) to $$INSTALL_DIR/$(PRODUCT)"

test:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift test

format:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift format \
		--in-place \
		--recursive \
		Package.swift Sources Tests

lint:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift format lint \
		--recursive \
		Package.swift Sources Tests

check: lint test

clean:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift package clean
