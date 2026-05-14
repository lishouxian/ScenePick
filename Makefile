.PHONY: test build icon app dist clean

test:
	swift build --product ScenePick
	SCENEPICK_BIN_DIR="$$(swift build --product ScenePick --show-bin-path)" swift run ScenePickLocalizationSelfTest
	swift run BingWallpapersCoreSelfTest
	swift run ScenePickLoginItemSelfTest

build:
	swift build --product ScenePick

icon:
	swift Scripts/generate-icon.swift

app:
	./Scripts/build-app.sh

verify-app:
	./Scripts/verify-app-bundle.sh

dist: app verify-app
	./Scripts/package-release.sh

clean:
	rm -rf Build Dist
