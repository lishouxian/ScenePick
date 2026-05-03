import AppKit
import BingWallpapersCore
import SwiftUI

@main
struct ScenePickApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycleDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @StateObject private var store = WallpaperStore()
    @AppStorage(BingWallpaperDefaultKeys.selectedMarket, store: BingWallpaperDefaults.store)
    private var selectedMarketRaw = BingMarket.china.rawValue
    @AppStorage(BingWallpaperDefaultKeys.selectedResolution, store: BingWallpaperDefaults.store)
    private var selectedResolutionRaw = WallpaperResolution.uhd.rawValue
    @AppStorage(BingWallpaperDefaultKeys.fillMode, store: BingWallpaperDefaults.store)
    private var fillModeRaw = WallpaperFillMode.fillScreen.rawValue
    @AppStorage(BingWallpaperDefaultKeys.dailyAutoUpdateEnabled, store: BingWallpaperDefaults.store)
    private var dailyAutoUpdateEnabled = false
    @AppStorage(BingWallpaperDefaultKeys.selectedLanguage, store: BingWallpaperDefaults.store)
    private var selectedLanguageRaw = AppLanguage.system.rawValue

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
        Window(L10n.string("app.name"), id: "main") {
            ContentView(
                store: store,
                selectedMarketRaw: $selectedMarketRaw,
                selectedResolutionRaw: $selectedResolutionRaw,
                fillModeRaw: $fillModeRaw,
                dailyAutoUpdateEnabled: $dailyAutoUpdateEnabled,
                selectedLanguageRaw: $selectedLanguageRaw
            )
            .frame(minWidth: 1120, minHeight: 620)
            .task {
                await store.load(market: selectedMarket)
            }
        }
        .defaultSize(width: 1240, height: 660)

        MenuBarExtra(
            L10n.string("app.name"),
            systemImage: "photo.on.rectangle.angled"
        ) {
            MenuBarContentView(
                store: store,
                market: selectedMarket,
                resolution: selectedResolution,
                fillMode: fillMode,
                dailyAutoUpdateEnabled: $dailyAutoUpdateEnabled,
                openApp: {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
