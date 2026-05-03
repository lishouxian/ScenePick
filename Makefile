.PHONY: test build icon app

test:
	swift run BingWallpapersCoreSelfTest

build:
	swift build --product BingWallpaperSwitcher

icon:
	swift Scripts/generate-icon.swift

app: icon
	./Scripts/build-app.sh
