import BingWallpapersCore
import Foundation

@main
struct BingWallpaperAgent {
    @MainActor
    static func main() async {
        do {
            let defaults = BingWallpaperDefaults.store
            let market = BingMarket(
                rawValue: defaults.string(forKey: BingWallpaperDefaultKeys.selectedMarket) ?? BingMarket.china.rawValue
            ) ?? .china
            let resolution = WallpaperResolution(
                rawValue: defaults.string(forKey: BingWallpaperDefaultKeys.selectedResolution) ?? WallpaperResolution.uhd.rawValue
            ) ?? .uhd
            let fillMode = WallpaperFillMode(
                rawValue: defaults.string(forKey: BingWallpaperDefaultKeys.fillMode) ?? WallpaperFillMode.fillScreen.rawValue
            ) ?? .fillScreen

            let images = try await BingWallpaperService().fetchArchive(market: market, count: 1)
            guard let latest = images.first else {
                throw BingWallpaperError.emptyArchive
            }

            let fileURL = try await WallpaperCache().cachedImageURL(
                for: latest,
                resolution: resolution
            )
            try MacDesktopWallpaperSetter().setDesktopImage(
                fileURL: fileURL,
                fillMode: fillMode
            )

            print("Set latest \(market.label) Bing wallpaper: \(latest.displayTitle)")
        } catch {
            fputs("BingWallpaperAgent failed: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }
}
