SCHEME := sc-2
PROJECT := sc-2.xcodeproj
BUNDLE_ID := com.gleninc.sc-2
SIM_NAME := iPhone 16
DD := build

.PHONY: build run install launch clean test refresh-lsp

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -configuration Debug \
	  -destination "platform=iOS Simulator,name=$(SIM_NAME)" \
	  -derivedDataPath $(DD) \
	  build

install:
	xcrun simctl bootstatus booted -b
	xcrun simctl install booted $(DD)/Build/Products/Debug-iphonesimulator/$(SCHEME).app

launch:
	xcrun simctl launch booted $(BUNDLE_ID)

run: build install launch

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(DD)

test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination "platform=iOS Simulator,name=$(SIM_NAME)" test

refresh-lsp:
	rm -rf .bundle
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination "platform=iOS Simulator,name=$(SIM_NAME)" \
	  -resultBundlePath .bundle \
	  build | xcode-build-server parse -a
