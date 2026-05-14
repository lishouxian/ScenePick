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
        .library(
            name: "ScenePickSupport",
            targets: ["ScenePickSupport"]
        ),
        .executable(
            name: "ScenePick",
            targets: ["ScenePick"]
        ),
        .executable(
            name: "BingWallpapersCoreSelfTest",
            targets: ["BingWallpapersCoreSelfTest"]
        ),
        .executable(
            name: "ScenePickLoginItemSelfTest",
            targets: ["ScenePickLoginItemSelfTest"]
        )
    ],
    targets: [
        .target(
            name: "BingWallpapersCore",
            resources: [.process("Resources")]
        ),
        .target(
            name: "ScenePickSupport"
        ),
        .executableTarget(
            name: "ScenePick",
            dependencies: ["BingWallpapersCore", "ScenePickSupport"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "BingWallpapersCoreSelfTest",
            dependencies: ["BingWallpapersCore"]
        ),
        .executableTarget(
            name: "ScenePickLoginItemSelfTest",
            dependencies: ["ScenePickSupport"]
        ),
        .executableTarget(
            name: "ScenePickLocalizationSelfTest",
            dependencies: ["BingWallpapersCore"]
        )
    ]
)
