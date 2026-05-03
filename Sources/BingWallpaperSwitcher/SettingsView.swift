import AppKit
import BingWallpapersCore
import SwiftUI

struct SettingsView: View {
    @Binding var selectedMarketRaw: String
    @Binding var selectedResolutionRaw: String
    @Binding var fillModeRaw: String
    @Binding var autoSetLatestOnLaunch: Bool
    @State private var cacheMessage: String?

    var body: some View {
        Form {
            Picker("Default Region", selection: $selectedMarketRaw) {
                ForEach(BingMarket.allCases) { market in
                    Text(market.label).tag(market.rawValue)
                }
            }

            Picker("Wallpaper Quality", selection: $selectedResolutionRaw) {
                ForEach(WallpaperResolution.allCases) { resolution in
                    Text(resolution.label).tag(resolution.rawValue)
                }
            }

            Picker("Desktop Mode", selection: $fillModeRaw) {
                ForEach(WallpaperFillMode.allCases) { mode in
                    Text(mode.label).tag(mode.rawValue)
                }
            }

            Toggle("Set latest Bing wallpaper on launch", isOn: $autoSetLatestOnLaunch)

            LabeledContent("Cache") {
                HStack {
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([
                            WallpaperCache.defaultDirectory
                        ])
                    }

                    Button("Clear") {
                        clearCache()
                    }
                }
            }

            if let cacheMessage {
                Text(cacheMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func clearCache() {
        do {
            try WallpaperCache().removeAll()
            cacheMessage = "Cache cleared."
        } catch {
            cacheMessage = error.localizedDescription
        }
    }
}
