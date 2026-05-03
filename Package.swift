// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BingWallpaperSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BingWallpapersCore",
            targets: ["BingWallpapersCore"]
        ),
        .executable(
            name: "BingWallpaperSwitcher",
            targets: ["BingWallpaperSwitcher"]
        ),
        .executable(
            name: "BingWallpapersCoreSelfTest",
            targets: ["BingWallpapersCoreSelfTest"]
        )
    ],
    targets: [
        .target(
            name: "BingWallpapersCore"
        ),
        .executableTarget(
            name: "BingWallpaperSwitcher",
            dependencies: ["BingWallpapersCore"]
        ),
        .executableTarget(
            name: "BingWallpapersCoreSelfTest",
            dependencies: ["BingWallpapersCore"]
        )
    ]
)
