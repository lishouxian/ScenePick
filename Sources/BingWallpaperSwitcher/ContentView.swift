import BingWallpapersCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @Binding var selectedMarketRaw: String
    @Binding var selectedResolutionRaw: String
    @Binding var fillModeRaw: String
    @Binding var autoSetLatestOnLaunch: Bool

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
                selectedMarketRaw: $selectedMarketRaw
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
                Picker("Quality", selection: $selectedResolutionRaw) {
                    ForEach(WallpaperResolution.allCases) { resolution in
                        Text(resolution.label).tag(resolution.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                Picker("Desktop Mode", selection: $fillModeRaw) {
                    ForEach(WallpaperFillMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)

                Button {
                    Task { await store.load(market: selectedMarket) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
        }
        .onChange(of: selectedMarketRaw) { newValue in
            let market = BingMarket(rawValue: newValue) ?? .china
            Task { await store.load(market: market) }
        }
    }
}

private struct WallpaperSidebar: View {
    @ObservedObject var store: WallpaperStore
    @Binding var selectedMarketRaw: String

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bing Wallpapers")
                    .font(.title2.weight(.semibold))

                Picker("Region", selection: $selectedMarketRaw) {
                    ForEach(BingMarket.allCases) { market in
                        Text(market.label).tag(market.rawValue)
                    }
                }
                .pickerStyle(.menu)
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
        guard let loadingMarket = store.loadingMarket else {
            return "Loading Bing archive"
        }

        return "Loading \(loadingMarket.label)"
    }
}

private struct WallpaperRow: View {
    let wallpaper: BingImage

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: wallpaper.previewURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.secondary.opacity(0.12)
                        ProgressView()
                            .controlSize(.small)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.secondary.opacity(0.12))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 86, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.displayTitle)
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
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            if let wallpaper = store.selectedWallpaper {
                VStack(spacing: 18) {
                    WallpaperPreview(wallpaper: wallpaper, resolution: resolution)

                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            store.selectPrevious()
                        } label: {
                            Label("Previous", systemImage: "chevron.left")
                        }

                        Button {
                            Task {
                                await store.setSelectedAsDesktop(
                                    resolution: resolution,
                                    fillMode: fillMode
                                )
                            }
                        } label: {
                            Label("Set Desktop", systemImage: "desktopcomputer")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(store.isSettingDesktop)

                        Button {
                            store.selectNext()
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                        }

                        Spacer()

                        if let copyrightLink = wallpaper.copyrightLink,
                           let url = URL(string: copyrightLink) {
                            Link(destination: url) {
                                Label("Source", systemImage: "link")
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

            Text("No Wallpapers")
                .font(.title3.weight(.semibold))

            Text("Refresh to load the latest Bing wallpapers.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}

private struct WallpaperPreview: View {
    let wallpaper: BingImage
    let resolution: WallpaperResolution

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: wallpaper.imageURL(resolution: resolution)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.secondary.opacity(0.14)
                            ProgressView("Loading preview")
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            Color.secondary.opacity(0.14)
                            Image(systemName: "photo")
                                .font(.system(size: 56, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(wallpaper.displayTitle)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(wallpaper.copyrightText)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }
                .padding(22)
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
        if let errorMessage {
            return errorMessage
        }

        if isSetting {
            return "Downloading and applying wallpaper."
        }

        if isLoading {
            return "Refreshing Bing archive."
        }

        return statusMessage ?? "Ready."
    }
}
