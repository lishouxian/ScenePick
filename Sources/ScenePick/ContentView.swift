import AppKit
import BingWallpapersCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @Binding var selectedMarketRaw: String
    @Binding var selectedResolutionRaw: String
    @Binding var fillModeRaw: String
    @Binding var dailyAutoUpdateEnabled: Bool

    private var selectedMarket: BingMarket {
        BingMarket(rawValue: selectedMarketRaw) ?? .china
    }

    private var selectedResolution: WallpaperResolution {
        WallpaperResolution(rawValue: selectedResolutionRaw) ?? .uhd
    }

    private var fillMode: WallpaperFillMode {
        WallpaperFillMode(rawValue: fillModeRaw) ?? .fillScreen
    }

    var body: some View {
        NavigationSplitView {
            WallpaperSidebar(
                store: store,
                selectedMarketRaw: $selectedMarketRaw,
                dailyAutoUpdateEnabled: $dailyAutoUpdateEnabled
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            WallpaperDetailView(
                store: store,
                resolution: selectedResolution,
                fillMode: fillMode
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Picker(L10n.string("toolbar.wallpaperQuality"), selection: $selectedResolutionRaw) {
                        ForEach(WallpaperResolution.allCases) { resolution in
                            Text(resolution.localizedLabel).tag(resolution.rawValue)
                        }
                    }

                    Picker(L10n.string("toolbar.fillMode"), selection: $fillModeRaw) {
                        ForEach(WallpaperFillMode.allCases) { mode in
                            Text(mode.localizedLabel).tag(mode.rawValue)
                        }
                    }

                    Divider()

                    Button {
                        Task { await store.load(market: selectedMarket, forceRefresh: true) }
                    } label: {
                        Label(L10n.string("action.reloadWallpapers"), systemImage: "arrow.clockwise")
                    }
                    .disabled(store.isLoading)

                    Divider()

                    Button {
                        revealCache()
                    } label: {
                        Label(L10n.string("action.revealCache"), systemImage: "folder")
                    }

                    Button(role: .destructive) {
                        store.clearCache()
                    } label: {
                        Label(L10n.string("action.clearCache"), systemImage: "trash")
                    }
                } label: {
                    Label(L10n.string("toolbar.more"), systemImage: "ellipsis.circle")
                }
            }
        }
        .onChange(of: selectedMarketRaw) { newValue in
            let market = BingMarket(rawValue: newValue) ?? .china
            Task { await store.load(market: market) }
        }
        .onChange(of: dailyAutoUpdateEnabled) { _ in
            InAppDailyWallpaperUpdater.shared.start()
        }
    }

    private func revealCache() {
        NSWorkspace.shared.activateFileViewerSelecting([
            WallpaperCache.defaultDirectory
        ])
    }

}

private struct DailyUpdateSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.accentColor : Color(red: 0.83, green: 0.84, blue: 0.85))
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.black.opacity(configuration.isOn ? 0.0 : 0.06), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 1.5, x: 0, y: 1)

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, x: 0, y: 1)
                    .padding(3)
                    .offset(x: configuration.isOn ? 9 : -9)
            }
            .frame(width: 42, height: 24)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: configuration.isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string("accessibility.dailyUpdate"))
        .accessibilityValue(configuration.isOn ? L10n.string("state.on") : L10n.string("state.off"))
    }
}

private struct WallpaperSidebar: View {
    @ObservedObject var store: WallpaperStore
    @Binding var selectedMarketRaw: String
    @Binding var dailyAutoUpdateEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.string("app.name"))
                    .font(.title2.weight(.semibold))

                Picker(L10n.string("sidebar.region"), selection: $selectedMarketRaw) {
                    ForEach(BingMarket.allCases) { market in
                        Text(market.localizedLabel).tag(market.rawValue)
                    }
                }
                .pickerStyle(.menu)

                DailyUpdatePreferenceRow(isOn: $dailyAutoUpdateEnabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top], 18)
            .padding(.bottom, 14)

            Divider()

            List(selection: $store.selectedWallpaperID) {
                ForEach(store.wallpapers) { wallpaper in
                    WallpaperRow(wallpaper: wallpaper)
                        .tag(wallpaper.id)
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if store.isLoading && store.wallpapers.isEmpty {
                    ProgressView(loadingText)
                }
            }
        }
    }

    private var loadingText: String {
        L10n.string("loading.bingArchive")
    }
}

private struct DailyUpdatePreferenceRow: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(L10n.string("dailyUpdate.title"))
                .font(.callout.weight(.medium))

            Spacer()

            Toggle(L10n.string("dailyUpdate.title"), isOn: $isOn)
                .labelsHidden()
                .toggleStyle(DailyUpdateSwitchToggleStyle())
        }
        .help(L10n.string("dailyUpdate.help"))
    }
}

private struct WallpaperRow: View {
    let wallpaper: BingImage

    var body: some View {
        HStack(spacing: 12) {
            CachedWallpaperImage(
                wallpaper: wallpaper,
                resolution: .preview,
                contentMode: .fill
            )
            .frame(width: 86, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.localizedDisplayTitle)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                Text(wallpaper.startDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct WallpaperDetailView: View {
    @ObservedObject var store: WallpaperStore
    let resolution: WallpaperResolution
    let fillMode: WallpaperFillMode

    var body: some View {
        ZStack(alignment: .top) {
            Color(nsColor: .windowBackgroundColor)

            if let wallpaper = store.selectedWallpaper {
                VStack(spacing: 18) {
                    WallpaperPreview(wallpaper: wallpaper)

                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            store.selectPrevious()
                        } label: {
                            Label(L10n.string("action.previous"), systemImage: "chevron.left")
                        }

                        Button {
                            Task {
                                await store.setSelectedAsDesktop(
                                    resolution: resolution,
                                    fillMode: fillMode
                                )
                            }
                        } label: {
                            Label(L10n.string("action.setDesktop"), systemImage: "desktopcomputer")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(minWidth: 150)
                        .layoutPriority(1)
                        .disabled(store.isSettingDesktop)

                        Button {
                            store.selectNext()
                        } label: {
                            Label(L10n.string("action.next"), systemImage: "chevron.right")
                        }

                        Spacer()

                        if let copyrightLink = wallpaper.copyrightLink,
                           let url = URL(string: copyrightLink) {
                            Link(destination: url) {
                                Label(L10n.string("action.source"), systemImage: "link")
                            }
                        }
                    }

                    StatusMessageView(
                        isLoading: store.isLoading,
                        isSetting: store.isSettingDesktop,
                        statusMessage: store.statusMessage,
                        errorMessage: store.errorMessage
                    )
                }
                .padding(24)
            } else {
                EmptyWallpapersView()
            }
        }
    }
}

private struct EmptyWallpapersView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 42, weight: .regular))
                .foregroundColor(.secondary)

            Text(L10n.string("empty.title"))
                .font(.title3.weight(.semibold))

            Text(L10n.string("empty.subtitle"))
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}

private struct WallpaperPreview: View {
    let wallpaper: BingImage

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                CachedWallpaperImage(
                    wallpaper: wallpaper,
                    resolution: .preview,
                    contentMode: .fill
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(wallpaper.localizedDisplayTitle)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(wallpaper.copyrightText)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }
                .padding(22)

                VStack {
                    HStack {
                        Spacer()
                        Text(L10n.string("preview.badge"))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.86))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.42))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    Spacer()
                }
                .padding(16)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct StatusMessageView: View {
    let isLoading: Bool
    let isSetting: Bool
    let statusMessage: String?
    let errorMessage: String?

    var body: some View {
        HStack(spacing: 8) {
            if isLoading || isSetting {
                ProgressView()
                    .controlSize(.small)
            }

            Text(message)
                .font(.footnote)
                .foregroundColor(errorMessage == nil ? .secondary : .red)
                .lineLimit(2)

            Spacer()
        }
        .frame(minHeight: 24)
    }

    private var message: String {
        if let errorMessage { return errorMessage }
        if isSetting {
            return statusMessage ?? L10n.string("status.downloadingApplying")
        }
        if isLoading {
            return L10n.string("status.reloading")
        }
        return statusMessage ?? L10n.string("status.ready")
    }
}
