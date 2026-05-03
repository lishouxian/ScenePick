import BingWallpapersCore
import SwiftUI

@main
struct BingWallpaperSwitcherApp: App {
    @StateObject private var store = WallpaperStore()
    @AppStorage("selectedMarket") private var selectedMarketRaw = BingMarket.china.rawValue
    @AppStorage("selectedResolution") private var selectedResolutionRaw = WallpaperResolution.uhd.rawValue
    @AppStorage("fillMode") private var fillModeRaw = WallpaperFillMode.fillScreen.rawValue
    @AppStorage("autoSetLatestOnLaunch") private var autoSetLatestOnLaunch = false

    private var selectedMarket: BingMarket {
        BingMarket(rawValue: selectedMarketRaw) ?? .china
    }

    private var selectedResolution: WallpaperResolution {
        WallpaperResolution(rawValue: selectedResolutionRaw) ?? .uhd
    }

    private var fillMode: WallpaperFillMode {
        WallpaperFillMode(rawValue: fillModeRaw) ?? .fillScreen
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                store: store,
                selectedMarketRaw: $selectedMarketRaw,
                selectedResolutionRaw: $selectedResolutionRaw,
                fillModeRaw: $fillModeRaw,
                autoSetLatestOnLaunch: $autoSetLatestOnLaunch
            )
            .frame(minWidth: 980, minHeight: 640)
            .task {
                await store.load(market: selectedMarket)
                if autoSetLatestOnLaunch {
                    await store.setLatestAsDesktop(
                        market: selectedMarket,
                        resolution: selectedResolution,
                        fillMode: fillMode
                    )
                }
            }
        }

        MenuBarExtra("Bing Wallpaper", systemImage: "photo.on.rectangle.angled") {
            MenuBarContentView(
                store: store,
                market: selectedMarket,
                resolution: selectedResolution,
                fillMode: fillMode
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                selectedMarketRaw: $selectedMarketRaw,
                selectedResolutionRaw: $selectedResolutionRaw,
                fillModeRaw: $fillModeRaw,
                autoSetLatestOnLaunch: $autoSetLatestOnLaunch
            )
        }
    }
}
