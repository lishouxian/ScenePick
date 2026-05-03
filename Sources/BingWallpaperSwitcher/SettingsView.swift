import AppKit
import BingWallpapersCore
import SwiftUI

struct SettingsView: View {
    @Binding var selectedMarketRaw: String
    @Binding var selectedResolutionRaw: String
    @Binding var fillModeRaw: String
    @Binding var autoSetLatestOnLaunch: Bool
    @Binding var dailyAutoUpdateEnabled: Bool
    @Binding var showDockIcon: Bool
    @Binding var showMenuBarIcon: Bool
    @State private var cacheMessage: String?
    @State private var automationMessage: String?
    @State private var isConfiguringDailyUpdate = false

    var body: some View {
        Form {
            Section("Wallpaper") {
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
            }

            Section("Automation") {
                Toggle("Update latest wallpaper every day in background", isOn: $dailyAutoUpdateEnabled)
                    .disabled(isConfiguringDailyUpdate)
                Text("Runs at 08:30 using a LaunchAgent. The main app does not need to stay open.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if isConfiguringDailyUpdate {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Updating background schedule.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let automationMessage {
                    Text(automationMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Visibility") {
                Toggle("Show app in Dock", isOn: $showDockIcon)
                Toggle("Show app in menu bar", isOn: $showMenuBarIcon)
            }

            Section("Cache") {
                LabeledContent("Images") {
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
        }
        .padding(24)
        .frame(width: 500)
        .onChange(of: dailyAutoUpdateEnabled) { enabled in
            configureDailyUpdate(enabled: enabled)
        }
    }

    private func clearCache() {
        do {
            try WallpaperCache().removeAll()
            cacheMessage = "Cache cleared."
        } catch {
            cacheMessage = error.localizedDescription
        }
    }

    private func configureDailyUpdate(enabled: Bool) {
        guard !isConfiguringDailyUpdate else {
            return
        }

        let appBundleURL = Bundle.main.bundleURL
        isConfiguringDailyUpdate = true
        automationMessage = nil

        Task {
            let result = await Task.detached(priority: .utility) {
                Result {
                    if enabled {
                        try DailyWallpaperScheduler.install(appBundleURL: appBundleURL)
                    } else {
                        try DailyWallpaperScheduler.uninstall()
                    }
                }
            }.value

            isConfiguringDailyUpdate = false

            switch result {
            case .success:
                automationMessage = enabled
                    ? "Daily background update is enabled."
                    : "Daily background update is disabled."
            case .failure(let error):
                automationMessage = error.localizedDescription
                if enabled {
                    dailyAutoUpdateEnabled = false
                }
            }
        }
    }
}
