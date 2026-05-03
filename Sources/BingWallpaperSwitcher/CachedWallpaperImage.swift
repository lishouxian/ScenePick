import AppKit
import BingWallpapersCore
import SwiftUI

struct CachedWallpaperImage: View {
    let wallpaper: BingImage
    let resolution: WallpaperResolution
    let contentMode: ContentMode

    @StateObject private var loader = CachedWallpaperImageLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.secondary.opacity(0.14)
                Image(systemName: "photo")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.secondary)
            }

            if loader.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .task(id: "\(wallpaper.id)-\(resolution.rawValue)") {
            await loader.load(wallpaper: wallpaper, resolution: resolution)
        }
    }
}

@MainActor
private final class CachedWallpaperImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false

    private let cache: WallpaperCache

    init(cache: WallpaperCache = WallpaperCache()) {
        self.cache = cache
    }

    func load(wallpaper: BingImage, resolution: WallpaperResolution) async {
        isLoading = true
        image = nil
        defer {
            isLoading = false
        }

        do {
            let fileURL = try await cache.cachedImageURL(
                for: wallpaper,
                resolution: resolution
            )

            guard !Task.isCancelled else {
                return
            }

            image = NSImage(contentsOf: fileURL)
        } catch {
            image = nil
        }
    }
}
