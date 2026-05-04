.PHONY: test build icon app dist clean

test:
	swift run BingWallpapersCoreSelfTest

build:
	swift build --product ScenePick

icon:
	swift Scripts/generate-icon.swift

app:
	./Scripts/build-app.sh

dist: app
	./Scripts/package-release.sh

clean:
	rm -rf Build Dist
