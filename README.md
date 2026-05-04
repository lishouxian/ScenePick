# ScenePick / 拾景

ScenePick (拾景) is a native macOS menu bar app for browsing Bing daily wallpapers, previewing images, and applying them as the desktop wallpaper across all connected displays.

## Features

- Browse the latest Bing wallpaper archive by region.
- Preview wallpapers before applying them.
- Apply the selected, latest, previous, or next wallpaper from the app or menu bar.
- Cache metadata, previews, and downloaded wallpaper files for faster switching.
- Choose UHD, HD 1080p, or preview quality.
- Choose fill or fit desktop scaling.
- Enable daily automatic wallpaper switching while the app is running.
- Use English or Simplified Chinese UI.
- Run as a pure menu bar app with no Dock icon.

## Install

### Download DMG

Download `ScenePick.dmg` from the GitHub Release, open it, then drag `ScenePick.app` into `Applications`.

DMG vs ZIP:

- DMG gives a more Mac-native install experience and can include an `Applications` shortcut for drag-install.
- ZIP is simpler and useful for CI artifacts or manual copying.
- Neither format bypasses Gatekeeper. For public distribution, sign with a Developer ID certificate and notarize the DMG or ZIP.

If macOS blocks an unsigned local build, remove quarantine after installing:

```bash
xattr -dr com.apple.quarantine /Applications/ScenePick.app
```

### Homebrew

This repo includes a Cask template at `Casks/scene-pick.rb`.

For a normal Homebrew install, copy `Casks/scene-pick.rb` into a Homebrew tap repository, then install from that tap:

```bash
brew tap lishouxian/tap
brew install --cask scene-pick
```

For one-off Cask testing after a GitHub Release exists:

```bash
brew install --cask ./Casks/scene-pick.rb
```

If the GitHub repository is not `lishouxian/ScenePick`, update the `url` and `homepage` in `Casks/scene-pick.rb` before publishing the Cask.

## Development

Requirements:

- macOS 13 or later
- Xcode or Command Line Tools with Swift 6 support

Run the app during development:

```bash
swift run ScenePick
```

Run tests:

```bash
make test
```

This project uses a small self-test executable because the Command Line Tools environment on this machine does not expose `XCTest` or Swift `Testing`.

Build the debug product:

```bash
make build
```

## Packaging

Build a release `.app` bundle:

```bash
make app
```

The app bundle is written to:

```text
Build/ScenePick.app
```

Use `make dist` for files that will be copied to another machine. The packaging step stages a clean copy before signing, which avoids extended-attribute issues that can appear in synced folders such as `Documents`.

Build distributable DMG and ZIP artifacts:

```bash
make dist
```

Artifacts are written to:

```text
Dist/ScenePick.dmg
Dist/ScenePick.zip
Dist/SHA256SUMS
```

The packaging scripts clear common macOS extended attributes, ad-hoc sign the app by default, and verify the resulting bundle. To sign with a real certificate:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make dist
```

Version metadata can be injected by CI or local release builds:

```bash
APP_VERSION=1.0.1 APP_BUILD=42 make dist
```

## GitHub Actions Release

The workflow in `.github/workflows/build.yml` runs on pushes, pull requests, manual dispatch, and `v*` tags.

It does the following:

- Runs `make test`.
- Builds `ScenePick.app`.
- Packages `ScenePick.dmg`, `ScenePick.zip`, and `SHA256SUMS`.
- Uploads the files as workflow artifacts.
- On a tag like `v1.0.1`, creates a GitHub Release and uploads the DMG, ZIP, and checksum file.

To cut a release:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Icon

Regenerate the app icon:

```bash
make icon
```
