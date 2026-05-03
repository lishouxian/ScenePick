import BingWallpapersCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: WallpaperStore
    let market: BingMarket
    let resolution: WallpaperResolution
    let fillMode: WallpaperFillMode
    let openApp: () -> Void
    let openPreferences: () -> Void

    var body: some View {
        Button {
            openApp()
        } label: {
            Label("Open App", systemImage: "macwindow")
        }

        Button {
            openPreferences()
        } label: {
            Label("Open Settings", systemImage: "gearshape")
        }

        Divider()

        Button {
            Task {
                await store.setLatestAsDesktop(
                    market: market,
                    resolution: resolution,
                    fillMode: fillMode
                )
            }
        } label: {
            Label("Set Latest Wallpaper", systemImage: "sparkles.rectangle.stack")
        }
        .disabled(store.isSettingDesktop)

        if let selected = store.selectedWallpaper {
            Button {
                Task {
                    await store.setSelectedAsDesktop(
                        resolution: resolution,
                        fillMode: fillMode
                    )
                }
            } label: {
                Label("Set Selected: \(selected.displayTitle)", systemImage: "desktopcomputer")
            }
            .disabled(store.isSettingDesktop)
        }

        Divider()

        Button {
            Task { await store.load(market: market) }
        } label: {
            Label("Refresh Archive", systemImage: "arrow.clockwise")
        }
        .disabled(store.isLoading)

        if let errorMessage = store.errorMessage {
            Divider()
            Text(errorMessage)
        }
    }
}
