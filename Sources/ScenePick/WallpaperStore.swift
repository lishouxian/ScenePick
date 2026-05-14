import AppKit
import BingWallpapersCore
import Foundation

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var wallpapers: [BingImage] = []
    @Published var selectedWallpaperID: BingImage.ID? {
        didSet {
            if oldValue != selectedWallpaperID {
                cancelStatusReset()
            }
        }
    }
    @Published private(set) var isLoading = false
    @Published private(set) var isSettingDesktop = false
    @Published var errorMessage: String?
    @Published private(set) var statusMessage: String?
    @Published private(set) var libraryDocument = WallpaperLibraryDocument.empty

    private let service: BingWallpaperService
    private let cache: WallpaperCache
    private let desktopSetter: DesktopWallpaperSetting
    private let libraryStore: any WallpaperLibraryStoring
    private var activeMarket: BingMarket?
    private var activeLoadID: UUID?
    private var archiveCache: [BingMarket: CachedArchive] = [:]
    private var previewPrefetchTask: Task<Void, Never>?
    private var statusResetTask: Task<Void, Never>?
    private let archiveCacheTTL: TimeInterval = 300
    private static let statusResetDelayNanoseconds: UInt64 = 3_000_000_000

    init(
        service: BingWallpaperService = BingWallpaperService(),
        cache: WallpaperCache = WallpaperCache(),
        desktopSetter: DesktopWallpaperSetting = MacDesktopWallpaperSetter(),
        libraryStore: any WallpaperLibraryStoring = JSONWallpaperLibraryStore()
    ) {
        self.service = service
        self.cache = cache
        self.desktopSetter = desktopSetter
        self.libraryStore = libraryStore
    }

    var selectedWallpaper: BingImage? {
        selectedWallpaper(filter: .all)
    }

    var favoriteWallpapers: [BingImage] {
        libraryDocument.favorites.map { $0.snapshot.image }
    }

    var recentWallpapers: [BingImage] {
        libraryDocument.recentSet.map { $0.snapshot.image }
    }

    func selectedWallpaper(filter: WallpaperListFilter) -> BingImage? {
        let visibleWallpapers = wallpapers(for: filter)
        return BingImageSelection.selectedImage(
            in: visibleWallpapers,
            selectedID: selectedWallpaperID
        )
    }

    func wallpapers(for filter: WallpaperListFilter) -> [BingImage] {
        switch filter {
        case .all:
            return wallpapers
        case .favorites:
            return favoriteWallpapers
        case .recent:
            return recentWallpapers
        }
    }

    func isFavorite(_ wallpaper: BingImage) -> Bool {
        libraryDocument.favorites.contains { $0.id == wallpaper.id }
    }

    func loadLibrary() {
        libraryStore.load()
        libraryDocument = libraryStore.document
        presentLibraryLoadIssueIfNeeded()
    }

    func presentLibraryLoadIssueIfNeeded() {
        switch libraryStore.loadIssue {
        case .unsupportedVersion:
            errorMessage = L10n.string("error.favoriteLibraryUnsupportedVersion")
        case .damagedJSONBackupCreated:
            errorMessage = L10n.string("error.favoriteLibraryDamagedBackupCreated")
        case .damagedJSONBackupFailed:
            errorMessage = L10n.string("error.favoriteLibraryDamagedBackupFailed")
        case nil:
            break
        }
    }

    func toggleFavorite(
        _ wallpaper: BingImage,
        market: BingMarket
    ) {
        cancelStatusReset()
        do {
            let shouldFavorite = !isFavorite(wallpaper)
            try libraryStore.setFavorite(
                wallpaper,
                market: market,
                isFavorite: shouldFavorite
            )
            libraryDocument = libraryStore.document
            errorMessage = nil
            statusMessage = shouldFavorite
                ? L10n.string("status.favoriteAdded")
                : L10n.string("status.favoriteRemoved")
            scheduleStatusReset()
        } catch WallpaperLibraryMutationError.unsupportedVersion {
            errorMessage = L10n.string("error.favoriteLibraryUnsupportedVersion")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ensureSelection(for filter: WallpaperListFilter) {
        let visibleWallpapers = wallpapers(for: filter)
        guard !visibleWallpapers.isEmpty else {
            selectedWallpaperID = nil
            return
        }

        selectedWallpaperID = BingImageSelection.selectedImage(
            in: visibleWallpapers,
            selectedID: selectedWallpaperID
        )?.id
    }

    func load(market: BingMarket, forceRefresh: Bool = false) async {
        let loadID = UUID()
        let isMarketChange = activeMarket != nil && activeMarket != market

        cancelStatusReset()
        activeLoadID = loadID
        previewPrefetchTask?.cancel()
        isLoading = true
        errorMessage = nil
        statusMessage = L10n.format("status.loadingWallpapers", market.localizedLabel)

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
            statusMessage = L10n.format("status.loadedCachedWallpapers", market.localizedLabel)
            finishLoading(loadID: loadID)
            return
        }

        do {
            let images = try await service.fetchAvailableArchive(market: market)
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
        statusResetTask?.cancel()
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
            statusMessage = L10n.format("status.loadedWallpapers", images.count, market.localizedLabel)
            return
        }

        selectedWallpaperID = images.first?.id
        errorMessage = nil
        statusMessage = L10n.format("status.loadedWallpapers", images.count, market.localizedLabel)
    }

    private func finishLoading(loadID: UUID) {
        if activeLoadID == loadID {
            isLoading = false
        }
    }

    func selectPrevious(filter: WallpaperListFilter = .all) {
        moveSelection(by: -1, filter: filter)
    }

    func selectNext(filter: WallpaperListFilter = .all) {
        moveSelection(by: 1, filter: filter)
    }

    func setSelectedAsDesktop(
        resolution: WallpaperResolution,
        fillMode: WallpaperFillMode,
        filter: WallpaperListFilter = .all,
        market: BingMarket? = nil
    ) async {
        guard let selectedWallpaper = selectedWallpaper(filter: filter) else {
            cancelStatusReset()
            errorMessage = L10n.string("error.selectWallpaperFirst")
            return
        }

        await setAsDesktop(
            selectedWallpaper,
            resolution: resolution,
            fillMode: fillMode,
            market: libraryMarket(for: selectedWallpaper, fallback: market)
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
            cancelStatusReset()
            errorMessage = L10n.string("error.noLatestWallpaper")
            return
        }

        selectedWallpaperID = latest.id
        await setAsDesktop(latest, resolution: resolution, fillMode: fillMode, market: market)
    }

    func setAdjacentAsDesktop(
        step: Int,
        market: BingMarket,
        resolution: WallpaperResolution,
        fillMode: WallpaperFillMode
    ) async {
        if wallpapers.isEmpty {
            await load(market: market)
        }

        guard let wallpaper = wallpaperAfterMovingSelection(by: step) else {
            cancelStatusReset()
            errorMessage = L10n.string("error.selectWallpaperFirst")
            return
        }

        selectedWallpaperID = wallpaper.id
        await setAsDesktop(wallpaper, resolution: resolution, fillMode: fillMode, market: market)
    }

    func clearCache() {
        cancelStatusReset()
        do {
            try cache.removeAll()
            errorMessage = nil
            statusMessage = L10n.string("status.cacheCleared")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearMessages() {
        cancelStatusReset()
        errorMessage = nil
        statusMessage = nil
    }

    private func setAsDesktop(
        _ wallpaper: BingImage,
        resolution: WallpaperResolution,
        fillMode: WallpaperFillMode,
        market: BingMarket?
    ) async {
        isSettingDesktop = true
        let wasCached = cache.isCached(for: wallpaper, resolution: resolution)
        clearMessages()
        statusMessage = wasCached
            ? L10n.format("status.usingCachedWallpaper", resolution.localizedLabel)
            : L10n.format("status.downloadingWallpaper", resolution.localizedLabel)
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
            recordRecent(wallpaper, market: market)

            statusMessage = L10n.format("status.setDesktop", wallpaper.localizedDisplayTitle)
            scheduleStatusReset()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func recordRecent(_ wallpaper: BingImage, market: BingMarket?) {
        do {
            try libraryStore.recordRecent(
                wallpaper,
                market: libraryMarket(for: wallpaper, fallback: market)
            )
            libraryDocument = libraryStore.document
        } catch {
            // Recent history should never turn a successful desktop change into a user-visible failure.
        }
    }

    private func libraryMarket(for wallpaper: BingImage, fallback: BingMarket?) -> BingMarket {
        if let favorite = libraryDocument.favorites.first(where: { $0.id == wallpaper.id }) {
            return favorite.snapshot.market
        }

        if let recent = libraryDocument.recentSet.first(where: { $0.id == wallpaper.id }) {
            return recent.snapshot.market
        }

        if let fallback {
            return fallback
        }

        return activeMarket ?? .china
    }

    private func moveSelection(by step: Int, filter: WallpaperListFilter) {
        let visibleWallpapers = wallpapers(for: filter)
        guard !visibleWallpapers.isEmpty else {
            return
        }

        guard let selectedWallpaperID,
              let index = visibleWallpapers.firstIndex(where: { $0.id == selectedWallpaperID }) else {
            self.selectedWallpaperID = visibleWallpapers.first?.id
            return
        }

        let nextIndex = (index + step + visibleWallpapers.count) % visibleWallpapers.count
        self.selectedWallpaperID = visibleWallpapers[nextIndex].id
    }

    private func wallpaperAfterMovingSelection(by step: Int) -> BingImage? {
        guard !wallpapers.isEmpty else {
            return nil
        }

        let currentIndex = selectedWallpaperID
            .flatMap { selectedID in
                wallpapers.firstIndex { $0.id == selectedID }
            } ?? 0
        let nextIndex = (currentIndex + step + wallpapers.count) % wallpapers.count
        return wallpapers[nextIndex]
    }

    private func scheduleStatusReset() {
        cancelStatusReset()
        statusResetTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.statusResetDelayNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            self?.clearStatusAfterResetDelay()
        }
    }

    private func cancelStatusReset() {
        statusResetTask?.cancel()
        statusResetTask = nil
    }

    private func clearStatusAfterResetDelay() {
        statusResetTask = nil

        guard !isLoading, !isSettingDesktop else {
            return
        }

        statusMessage = nil
    }

    private func prefetchPreviewImages(_ images: [BingImage]) {
        let cache = cache
        previewPrefetchTask?.cancel()
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
