import AppKit
import BingWallpapersCore
import Foundation

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var wallpapers: [BingImage] = []
    @Published var selectedWallpaperID: BingImage.ID?
    @Published private(set) var isLoading = false
    @Published private(set) var isSettingDesktop = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?

    private let service: BingWallpaperService
    private let cache: WallpaperCache
    private let desktopSetter: DesktopWallpaperSetting

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

    func load(market: BingMarket) async {
        guard !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let images = try await service.fetchArchive(market: market)
            wallpapers = images

            if let selectedWallpaperID,
               images.contains(where: { $0.id == selectedWallpaperID }) {
                return
            }

            selectedWallpaperID = images.first?.id
            errorMessage = nil
            statusMessage = "Loaded \(images.count) Bing wallpapers."
        } catch {
            errorMessage = error.localizedDescription
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
        clearMessages()
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
}
