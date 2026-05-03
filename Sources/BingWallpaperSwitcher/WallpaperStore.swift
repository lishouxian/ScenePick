import AppKit
import BingWallpapersCore
import Foundation

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var wallpapers: [BingImage] = []
    @Published var selectedWallpaperID: BingImage.ID?
    @Published private(set) var isLoading = false
    @Published private(set) var isSettingDesktop = false
    @Published private(set) var activeMarket: BingMarket?
    @Published private(set) var loadingMarket: BingMarket?
    @Published var errorMessage: String?
    @Published var statusMessage: String?

    private let service: BingWallpaperService
    private let cache: WallpaperCache
    private let desktopSetter: DesktopWallpaperSetting
    private var activeLoadID: UUID?
    private var archiveCache: [BingMarket: CachedArchive] = [:]
    private var previewPrefetchTask: Task<Void, Never>?
    private let archiveCacheTTL: TimeInterval = 300

    init(
        service: BingWallpaperService = BingWallpaperService(),
        cache: WallpaperCache = WallpaperCache(),
        desktopSetter: DesktopWallpaperSetting = MacDesktopWallpaperSetter()
    ) {
        self.service = service
        self.cache = cache
        self.desktopSetter = desktopSetter
    }

    var selectedWallpaper: BingImage? {
        guard let selectedWallpaperID else {
            return wallpapers.first
        }

        return wallpapers.first { $0.id == selectedWallpaperID }
    }

    func load(market: BingMarket, forceRefresh: Bool = false) async {
        let loadID = UUID()
        let isMarketChange = activeMarket != nil && activeMarket != market

        activeLoadID = loadID
        previewPrefetchTask?.cancel()
        loadingMarket = market
        isLoading = true
        errorMessage = nil
        statusMessage = "Loading \(market.label) wallpapers."

        if isMarketChange {
            wallpapers = []
            selectedWallpaperID = nil
        }

        if !forceRefresh,
           let cachedArchive = archiveCache[market],
           cachedArchive.isFresh(ttl: archiveCacheTTL) {
            applyWallpapers(
                cachedArchive.images,
                market: market,
                isMarketChange: isMarketChange
            )
            statusMessage = "Loaded cached \(market.label) wallpapers."
            finishLoading(loadID: loadID)
            return
        }

        do {
            let images = try await service.fetchArchive(market: market)
            guard activeLoadID == loadID else {
                return
            }

            archiveCache[market] = CachedArchive(images: images, loadedAt: Date())
            applyWallpapers(images, market: market, isMarketChange: isMarketChange)
        } catch {
            guard activeLoadID == loadID else {
                return
            }

            errorMessage = error.localizedDescription
        }

        finishLoading(loadID: loadID)
    }

    deinit {
        previewPrefetchTask?.cancel()
    }

    private func applyWallpapers(
        _ images: [BingImage],
        market: BingMarket,
        isMarketChange: Bool
    ) {
        activeMarket = market
        wallpapers = images
        prefetchPreviewImages(images)

        if !isMarketChange,
           let selectedWallpaperID,
           images.contains(where: { $0.id == selectedWallpaperID }) {
            statusMessage = "Loaded \(images.count) \(market.label) wallpapers."
            return
        }

        selectedWallpaperID = images.first?.id
        errorMessage = nil
        statusMessage = "Loaded \(images.count) \(market.label) wallpapers."
    }

    private func finishLoading(loadID: UUID) {
        if activeLoadID == loadID {
            isLoading = false
            loadingMarket = nil
        }
    }

    func selectPrevious() {
        moveSelection(by: -1)
    }

    func selectNext() {
        moveSelection(by: 1)
    }

    func setSelectedAsDesktop(
        resolution: WallpaperResolution,
        fillMode: WallpaperFillMode
    ) async {
        guard let selectedWallpaper else {
            errorMessage = "Select a wallpaper first."
            return
        }

        await setAsDesktop(
            selectedWallpaper,
            resolution: resolution,
            fillMode: fillMode
        )
    }

    func setLatestAsDesktop(
        market: BingMarket,
        resolution: WallpaperResolution,
        fillMode: WallpaperFillMode
    ) async {
        if wallpapers.isEmpty {
            await load(market: market)
        }

        guard let latest = wallpapers.first else {
            errorMessage = "Bing did not return a latest wallpaper."
            return
        }

        selectedWallpaperID = latest.id
        await setAsDesktop(latest, resolution: resolution, fillMode: fillMode)
    }

    func clearMessages() {
        errorMessage = nil
        statusMessage = nil
    }

    private func setAsDesktop(
        _ wallpaper: BingImage,
        resolution: WallpaperResolution,
        fillMode: WallpaperFillMode
    ) async {
        isSettingDesktop = true
        let wasCached = cache.isCached(for: wallpaper, resolution: resolution)
        clearMessages()
        statusMessage = wasCached
            ? "Using cached \(resolution.label) wallpaper."
            : "Downloading \(resolution.label) wallpaper."
        defer { isSettingDesktop = false }

        do {
            let fileURL = try await cache.cachedImageURL(
                for: wallpaper,
                resolution: resolution
            )
            try desktopSetter.setDesktopImage(
                fileURL: fileURL,
                fillMode: fillMode
            )

            statusMessage = "Set \(wallpaper.displayTitle) as desktop wallpaper."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveSelection(by step: Int) {
        guard !wallpapers.isEmpty else {
            return
        }

        guard let selectedWallpaperID,
              let index = wallpapers.firstIndex(where: { $0.id == selectedWallpaperID }) else {
            self.selectedWallpaperID = wallpapers.first?.id
            return
        }

        let nextIndex = (index + step + wallpapers.count) % wallpapers.count
        self.selectedWallpaperID = wallpapers[nextIndex].id
    }

    private func prefetchPreviewImages(_ images: [BingImage]) {
        let cache = cache
        previewPrefetchTask = Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                for image in images {
                    group.addTask {
                        guard !Task.isCancelled else {
                            return
                        }

                        _ = try? await cache.cachedImageURL(for: image, resolution: .preview)
                    }
                }
            }
        }
    }

    private struct CachedArchive {
        let images: [BingImage]
        let loadedAt: Date

        func isFresh(ttl: TimeInterval) -> Bool {
            Date().timeIntervalSince(loadedAt) < ttl
        }
    }
}
