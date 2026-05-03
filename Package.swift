// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ScenePick",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BingWallpapersCore",
            targets: ["BingWallpapersCore"]
        ),
        .executable(
            name: "ScenePick",
            targets: ["ScenePick"]
        ),
        .executable(
            name: "BingWallpapersCoreSelfTest",
            targets: ["BingWallpapersCoreSelfTest"]
        )
    ],
    targets: [
        .target(
            name: "BingWallpapersCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "ScenePick",
            dependencies: ["BingWallpapersCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "BingWallpapersCoreSelfTest",
            dependencies: ["BingWallpapersCore"]
        )
    ]
)
