# Bing Wallpaper Switcher

A native macOS SwiftUI app for browsing the latest Bing daily wallpapers, previewing high-resolution images, and applying them as the desktop wallpaper across all connected displays.

## Features

- Browse the latest Bing wallpaper archive by region.
- Preview the selected wallpaper in UHD, HD 1080p, or preview quality.
- Cache wallpaper metadata and downloaded images for faster switching.
- Use lightweight cached previews instead of downloading full-resolution images for browsing.
- Switch the macOS desktop wallpaper from the main window or status bar menu.
- Cache downloaded wallpaper files under Application Support.
- Pure status bar app with no Dock icon.
- Optional daily update while the app is running.
- Main-window controls for region, quality, scaling mode, daily update, and cache management.

## Development

```bash
swift run BingWallpaperSwitcher
```

## Test

```bash
make test
```

This project uses a small self-test executable because the Command Line Tools
environment on this machine does not expose `XCTest` or Swift `Testing`.

## Build `.app`

```bash
make app
```

The app bundle is written to `Build/Bing Wallpaper Switcher.app`.

## Regenerate App Icon

```bash
make icon
```
