import AppKit
import BingWallpapersCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @Binding var selectedMarketRaw: String
    @Binding var selectedResolutionRaw: String
    @Binding var fillModeRaw: String
    @Binding var dailyAutoUpdateEnabled: Bool
    @Binding var selectedLanguageRaw: String
    @State private var listFilter = WallpaperListFilter.all

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
            WallpaperSidebar(store: store, filter: $listFilter)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            WallpaperDetailView(
                store: store,
                filter: listFilter,
                market: selectedMarket,
                resolution: selectedResolution,
                fillMode: fillMode
            )
            .id(selectedLanguageRaw)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Picker(L10n.string("sidebar.region"), selection: $selectedMarketRaw) {
                        ForEach(BingMarket.allCases) { market in
                            Text(market.localizedLabel).tag(market.rawValue)
                        }
                    }

                    Toggle(L10n.string("dailyUpdate.title"), isOn: $dailyAutoUpdateEnabled)
                    Text(L10n.string("dailyUpdate.help"))

                    Divider()

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

                    Picker(L10n.string("toolbar.language"), selection: $selectedLanguageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.localizedLabel).tag(language.rawValue)
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
                .id(selectedLanguageRaw)
            }
        }
        .onChange(of: selectedMarketRaw) { newValue in
            let market = BingMarket(rawValue: newValue) ?? .china
            Task { await store.load(market: market) }
        }
        .onChange(of: dailyAutoUpdateEnabled) { _ in
            InAppDailyWallpaperUpdater.shared.start()
        }
        .onChange(of: selectedLanguageRaw) { _ in
            store.clearMessages()
        }
        .onChange(of: listFilter) { newValue in
            store.ensureSelection(for: newValue)
        }
    }

    private func revealCache() {
        NSWorkspace.shared.activateFileViewerSelecting([
            WallpaperCache.defaultDirectory
        ])
    }

}

enum WallpaperListFilter: String, CaseIterable, Identifiable {
    case all
    case favorites

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .all:
            return L10n.string("sidebar.filter.all")
        case .favorites:
            return L10n.string("sidebar.filter.favorites")
        }
    }
}

private struct WallpaperSidebar: View {
    @ObservedObject var store: WallpaperStore
    @Binding var filter: WallpaperListFilter

    private var visibleWallpapers: [BingImage] {
        store.wallpapers(for: filter)
    }

    var body: some View {
        VStack(spacing: 8) {
            Picker(L10n.string("sidebar.filter.label"), selection: $filter) {
                ForEach(WallpaperListFilter.allCases) { filter in
                    Text(filter.localizedLabel).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top], 10)

            List(selection: $store.selectedWallpaperID) {
                ForEach(visibleWallpapers) { wallpaper in
                    WallpaperRow(
                        wallpaper: wallpaper,
                        isFavorite: store.isFavorite(wallpaper)
                    )
                    .tag(wallpaper.id)
                }
            }
            .listStyle(.sidebar)
        }
        .overlay {
            if store.isLoading && store.wallpapers.isEmpty && filter == .all {
                ProgressView(loadingText)
            } else if filter == .favorites && store.favoriteWallpapers.isEmpty {
                EmptyFavoritesSidebarView()
            }
        }
    }

    private var loadingText: String {
        L10n.string("loading.bingArchive")
    }
}

private struct WallpaperRow: View {
    let wallpaper: BingImage
    let isFavorite: Bool

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

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyFavoritesSidebarView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.secondary)

            Text(L10n.string("empty.favorites.title"))
                .font(.callout.weight(.medium))

            Text(L10n.string("empty.favorites.subtitle"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 220)
        .padding()
    }
}

private struct WallpaperDetailView: View {
    @ObservedObject var store: WallpaperStore
    let filter: WallpaperListFilter
    let market: BingMarket
    let resolution: WallpaperResolution
    let fillMode: WallpaperFillMode

    var body: some View {
        ZStack(alignment: .top) {
            Color(nsColor: .windowBackgroundColor)

            if let wallpaper = store.selectedWallpaper(filter: filter) {
                VStack(spacing: 18) {
                    WallpaperPreview(wallpaper: wallpaper)

                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            store.selectPrevious(filter: filter)
                        } label: {
                            Label(L10n.string("action.previous"), systemImage: "chevron.left")
                        }

                        Button {
                            Task {
                                await store.setSelectedAsDesktop(
                                    resolution: resolution,
                                    fillMode: fillMode,
                                    filter: filter
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
                            store.selectNext(filter: filter)
                        } label: {
                            Label(L10n.string("action.next"), systemImage: "chevron.right")
                        }

                        Button {
                            store.toggleFavorite(wallpaper, market: market)
                            store.ensureSelection(for: filter)
                        } label: {
                            Label(
                                store.isFavorite(wallpaper)
                                    ? L10n.string("action.removeFavorite")
                                    : L10n.string("action.addFavorite"),
                                systemImage: store.isFavorite(wallpaper) ? "star.fill" : "star"
                            )
                        }
                        .help(
                            store.isFavorite(wallpaper)
                                ? L10n.string("action.removeFavorite")
                                : L10n.string("action.addFavorite")
                        )

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
                if filter == .favorites {
                    EmptyFavoritesDetailView()
                } else {
                    EmptyWallpapersView()
                }
            }
        }
    }
}

private struct EmptyFavoritesDetailView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "star")
                .font(.system(size: 42, weight: .regular))
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                Text(L10n.string("empty.favorites.title"))
                    .font(.title3.weight(.semibold))

                Text(L10n.string("empty.favorites.subtitle"))
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: 420)
        .padding(24)
    }
}

private struct EmptyWallpapersView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 42, weight: .regular))
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                Text(L10n.string("empty.title"))
                    .font(.title3.weight(.semibold))

                Text(L10n.string("empty.subtitle"))
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                OnboardingTip(
                    systemImage: "menubar.rectangle",
                    titleKey: "onboarding.menuBar.title",
                    descriptionKey: "onboarding.menuBar.description"
                )
                OnboardingTip(
                    systemImage: "desktopcomputer",
                    titleKey: "onboarding.setDesktop.title",
                    descriptionKey: "onboarding.setDesktop.description"
                )
                OnboardingTip(
                    systemImage: "calendar.badge.clock",
                    titleKey: "onboarding.dailyUpdate.title",
                    descriptionKey: "onboarding.dailyUpdate.description"
                )
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: 420)
        .padding(24)
    }
}

private struct OnboardingTip: View {
    let systemImage: String
    let titleKey: String
    let descriptionKey: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string(titleKey))
                    .font(.callout.weight(.medium))

                Text(L10n.string(descriptionKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
