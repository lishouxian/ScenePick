import AppKit
import BingWallpapersCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: WallpaperStore
    let market: BingMarket
    let resolution: WallpaperResolution
    let fillMode: WallpaperFillMode
    let languageRaw: String
    @Binding var dailyAutoUpdateEnabled: Bool
    let openApp: () -> Void
    @State private var latestWallpaperStatus = LatestWallpaperMenuStatus.idle
    @State private var latestWallpaperResetTask: Task<Void, Never>?

    private static let latestWallpaperResetDelayNanoseconds: UInt64 = 3_000_000_000

    var body: some View {
        Group {
            Button {
                openApp()
            } label: {
                Label(L10n.string("menu.openApp"), systemImage: "macwindow")
            }

            Button {
                dailyAutoUpdateEnabled.toggle()
            } label: {
                Label(L10n.string("menu.updateDaily"), systemImage: dailyAutoUpdateEnabled ? "checkmark.circle.fill" : "circle")
            }

            Button {
                resetLatestWallpaperStatus()
                Task {
                    await store.setAdjacentAsDesktop(
                        step: -1,
                        market: market,
                        resolution: resolution,
                        fillMode: fillMode
                    )
                }
            } label: {
                Label(L10n.string("menu.setPrevious"), systemImage: "chevron.left")
            }
            .disabled(store.isLoading || store.isSettingDesktop)

            Button {
                resetLatestWallpaperStatus()
                Task {
                    await store.setAdjacentAsDesktop(
                        step: 1,
                        market: market,
                        resolution: resolution,
                        fillMode: fillMode
                    )
                }
            } label: {
                Label(L10n.string("menu.setNext"), systemImage: "chevron.right")
            }
            .disabled(store.isLoading || store.isSettingDesktop)

            Button {
                Task {
                    setLatestWallpaperStatus(.running)
                    await store.setLatestAsDesktop(
                        market: market,
                        resolution: resolution,
                        fillMode: fillMode
                    )
                    setLatestWallpaperStatus(
                        store.errorMessage == nil ? .succeeded : .failed,
                        resetsAutomatically: store.errorMessage == nil
                    )
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
        .id(languageRaw)
        .onDisappear {
            latestWallpaperResetTask?.cancel()
            latestWallpaperResetTask = nil
        }
    }

    private var latestWallpaperTitle: String {
        if latestWallpaperStatus == .running {
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
        if latestWallpaperStatus == .running {
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

    private func setLatestWallpaperStatus(
        _ status: LatestWallpaperMenuStatus,
        resetsAutomatically: Bool = false
    ) {
        latestWallpaperResetTask?.cancel()
        latestWallpaperResetTask = nil
        latestWallpaperStatus = status

        guard resetsAutomatically else {
            return
        }

        latestWallpaperResetTask = Task {
            do {
                try await Task.sleep(nanoseconds: Self.latestWallpaperResetDelayNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            latestWallpaperStatus = .idle
            latestWallpaperResetTask = nil
        }
    }

    private func resetLatestWallpaperStatus() {
        setLatestWallpaperStatus(.idle)
    }
}

private enum LatestWallpaperMenuStatus {
    case idle
    case running
    case succeeded
    case failed
}
