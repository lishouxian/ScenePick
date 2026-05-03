import BingWallpapersCore
import SwiftUI

@main
struct BingWallpaperSwitcherApp: App {
    @StateObject private var store = WallpaperStore()
    @AppStorage(BingWallpaperDefaultKeys.selectedMarket, store: BingWallpaperDefaults.store)
    private var selectedMarketRaw = BingMarket.china.rawValue
    @AppStorage(BingWallpaperDefaultKeys.selectedResolution, store: BingWallpaperDefaults.store)
    private var selectedResolutionRaw = WallpaperResolution.uhd.rawValue
    @AppStorage(BingWallpaperDefaultKeys.fillMode, store: BingWallpaperDefaults.store)
    private var fillModeRaw = WallpaperFillMode.fillScreen.rawValue
    @AppStorage(BingWallpaperDefaultKeys.autoSetLatestOnLaunch, store: BingWallpaperDefaults.store)
    private var autoSetLatestOnLaunch = false
    @AppStorage(BingWallpaperDefaultKeys.dailyAutoUpdateEnabled, store: BingWallpaperDefaults.store)
    private var dailyAutoUpdateEnabled = false
    @AppStorage(BingWallpaperDefaultKeys.showDockIcon, store: BingWallpaperDefaults.store)
    private var showDockIcon = false
    @AppStorage(BingWallpaperDefaultKeys.showMenuBarIcon, store: BingWallpaperDefaults.store)
    private var showMenuBarIcon = true

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
            .onAppear {
                ApplicationVisibilityController.apply(showDockIcon: showDockIcon)
                if dailyAutoUpdateEnabled {
                    let appBundleURL = Bundle.main.bundleURL
                    Task.detached(priority: .utility) {
                        try? DailyWallpaperScheduler.install(appBundleURL: appBundleURL)
                    }
                }
            }
            .onChange(of: showDockIcon) { visible in
                ApplicationVisibilityController.apply(showDockIcon: visible)
            }
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

        MenuBarExtra(
            "Bing Wallpaper",
            systemImage: "photo.on.rectangle.angled",
            isInserted: $showMenuBarIcon
        ) {
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
                autoSetLatestOnLaunch: $autoSetLatestOnLaunch,
                dailyAutoUpdateEnabled: $dailyAutoUpdateEnabled,
                showDockIcon: $showDockIcon,
                showMenuBarIcon: $showMenuBarIcon
            )
        }
    }
}
