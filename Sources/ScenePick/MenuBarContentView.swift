import AppKit
import BingWallpapersCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: WallpaperStore
    let market: BingMarket
    let resolution: WallpaperResolution
    let fillMode: WallpaperFillMode
    @Binding var dailyAutoUpdateEnabled: Bool
    let openApp: () -> Void
    @State private var latestWallpaperStatus = LatestWallpaperMenuStatus.idle

    var body: some View {
        Button {
            openApp()
        } label: {
            Label(L10n.string("menu.openApp"), systemImage: "macwindow")
        }

        Toggle(isOn: $dailyAutoUpdateEnabled) {
            Label(L10n.string("menu.updateDaily"), systemImage: dailyAutoUpdateEnabled ? "checkmark.circle.fill" : "circle")
        }

        Button {
            Task {
                latestWallpaperStatus = .running
                await store.setLatestAsDesktop(
                    market: market,
                    resolution: resolution,
                    fillMode: fillMode
                )
                latestWallpaperStatus = store.errorMessage == nil ? .succeeded : .failed
            }
        } label: {
            Label(latestWallpaperTitle, systemImage: latestWallpaperSystemImage)
        }
        .disabled(store.isLoading || store.isSettingDesktop)

        Divider()

        Button {
            NSApp.terminate(nil)
        } label: {
            Label(L10n.string("menu.quit"), systemImage: "power")
        }
    }

    private var latestWallpaperTitle: String {
        if store.isLoading || store.isSettingDesktop || latestWallpaperStatus == .running {
            return L10n.string("menu.settingLatest")
        }
        if latestWallpaperStatus == .failed {
            return L10n.string("menu.setLatestFailed")
        }
        if latestWallpaperStatus == .succeeded {
            return L10n.string("menu.latestSet")
        }
        return L10n.string("menu.setLatest")
    }

    private var latestWallpaperSystemImage: String {
        if store.isLoading || store.isSettingDesktop || latestWallpaperStatus == .running {
            return "hourglass"
        }
        if latestWallpaperStatus == .failed {
            return "exclamationmark.triangle"
        }
        if latestWallpaperStatus == .succeeded {
            return "checkmark.circle.fill"
        }
        return "sparkles.rectangle.stack"
    }
}

private enum LatestWallpaperMenuStatus {
    case idle
    case running
    case succeeded
    case failed
}
