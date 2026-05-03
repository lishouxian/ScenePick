import AppKit
import BingWallpapersCore
import SwiftUI

struct CachedWallpaperImage: View {
    let wallpaper: BingImage
    let resolution: WallpaperResolution
    let contentMode: ContentMode
    let showsProgress: Bool

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
                    .font(.system(size: showsProgress ? 44 : 20, weight: .regular))
                    .foregroundColor(.secondary)
            }

            if loader.isLoading {
                ProgressOverlay(
                    progress: loader.progress,
                    showsProgress: showsProgress
                )
            }
        }
        .task(id: "\(wallpaper.id)-\(resolution.rawValue)") {
            await loader.load(wallpaper: wallpaper, resolution: resolution)
        }
    }
}

private struct ProgressOverlay: View {
    let progress: WallpaperDownloadProgress?
    let showsProgress: Bool

    var body: some View {
        if showsProgress {
            VStack(spacing: 10) {
                if let fraction = progress?.fractionCompleted {
                    ProgressView(value: fraction, total: 1)
                        .progressViewStyle(.linear)
                        .frame(width: 180)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            ProgressView()
                .controlSize(.small)
        }
    }
}

@MainActor
private final class CachedWallpaperImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var progress: WallpaperDownloadProgress?
    @Published var isLoading = false

    private let cache: WallpaperCache

    init(cache: WallpaperCache = WallpaperCache()) {
        self.cache = cache
    }

    func load(wallpaper: BingImage, resolution: WallpaperResolution) async {
        isLoading = true
        image = nil
        progress = nil
        defer {
            isLoading = false
            progress = nil
        }

        do {
            let fileURL = try await cache.cachedImageURL(
                for: wallpaper,
                resolution: resolution,
                onProgress: { [weak self] progress in
                    self?.progress = progress
                }
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
