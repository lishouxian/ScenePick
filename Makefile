.PHONY: test build app

test:
	swift run BingWallpapersCoreSelfTest

build:
	swift build --product BingWallpaperSwitcher

app:
	./Scripts/build-app.sh
