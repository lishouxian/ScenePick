import Foundation

public struct WallpaperLibraryDocument: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var favorites: [FavoriteWallpaper]
    public var recentSet: [RecentWallpaper]

    public init(
        version: Int = Self.currentVersion,
        favorites: [FavoriteWallpaper] = [],
        recentSet: [RecentWallpaper] = []
    ) {
        self.version = version
        self.favorites = favorites
        self.recentSet = recentSet
    }

    public static var empty: WallpaperLibraryDocument {
        WallpaperLibraryDocument()
    }
}

public struct WallpaperSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: BingImage.ID
    public var startDate: String
    public var market: BingMarket
    public var title: String
    public var copyright: String
    public var copyrightLink: String?
    public var url: String
    public var urlBase: String
    public var hash: String?

    public init(image: BingImage, market: BingMarket) {
        id = image.id
        startDate = image.startDate
        self.market = market
        title = image.title
        copyright = image.copyright
        copyrightLink = image.copyrightLink
        url = image.url
        urlBase = image.urlBase
        hash = image.hash
    }

    public var image: BingImage {
        BingImage(
            startDate: startDate,
            url: url,
            urlBase: urlBase,
            copyright: copyright,
            copyrightLink: copyrightLink,
            title: title,
            hash: hash
        )
    }
}

public struct FavoriteWallpaper: Codable, Equatable, Identifiable, Sendable {
    public var snapshot: WallpaperSnapshot
    public var favoritedAt: Date

    public var id: BingImage.ID { snapshot.id }

    public init(snapshot: WallpaperSnapshot, favoritedAt: Date) {
        self.snapshot = snapshot
        self.favoritedAt = favoritedAt
    }
}

public struct RecentWallpaper: Codable, Equatable, Identifiable, Sendable {
    public var snapshot: WallpaperSnapshot
    public var setAt: Date

    public var id: BingImage.ID { snapshot.id }

    public init(snapshot: WallpaperSnapshot, setAt: Date) {
        self.snapshot = snapshot
        self.setAt = setAt
    }
}

public enum WallpaperLibraryLoadIssue: Equatable, Sendable {
    case unsupportedVersion(Int)
    case damagedJSONBackupCreated(URL)
    case damagedJSONBackupFailed
}

public enum WallpaperLibraryMutationError: Error, Equatable, Sendable {
    case unsupportedVersion(Int)
}

@MainActor
public protocol WallpaperLibraryStoring: AnyObject {
    var document: WallpaperLibraryDocument { get }
    var loadIssue: WallpaperLibraryLoadIssue? { get }

    func load()
    func setFavorite(_ image: BingImage, market: BingMarket, isFavorite: Bool) throws
    func toggleFavorite(_ image: BingImage, market: BingMarket) throws
    func recordRecent(_ image: BingImage, market: BingMarket) throws
    func isFavorite(id: BingImage.ID) -> Bool
    func favoriteIDs() -> Set<BingImage.ID>
    func pinnedCacheFileNames(resolutions: [WallpaperResolution]) -> Set<String>
}

@MainActor
public final class JSONWallpaperLibraryStore: WallpaperLibraryStoring {
    public static let recentLimit = 50

    public private(set) var document: WallpaperLibraryDocument
    public private(set) var loadIssue: WallpaperLibraryLoadIssue?

    private let fileURL: URL
    private let fileManager: FileManager
    private let now: () -> Date
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var unsupportedVersion: Int?

    public init(
        fileURL: URL = JSONWallpaperLibraryStore.defaultFileURL,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.now = now
        document = .empty
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public static var defaultFileURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupport
            .appendingPathComponent("ScenePick", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("wallpapers.json", isDirectory: false)
    }

    public func load() {
        loadIssue = nil
        unsupportedVersion = nil

        guard fileManager.fileExists(atPath: fileURL.path) else {
            document = .empty
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let versionedDocument = try decoder.decode(VersionedWallpaperLibraryDocument.self, from: data)
            guard versionedDocument.version == WallpaperLibraryDocument.currentVersion else {
                document = .empty
                unsupportedVersion = versionedDocument.version
                loadIssue = .unsupportedVersion(versionedDocument.version)
                return
            }

            document = try decoder.decode(WallpaperLibraryDocument.self, from: data)
        } catch {
            document = .empty
            loadIssue = quarantineDamagedFile()
        }
    }

    public func setFavorite(
        _ image: BingImage,
        market: BingMarket,
        isFavorite: Bool
    ) throws {
        if let unsupportedVersion {
            throw WallpaperLibraryMutationError.unsupportedVersion(unsupportedVersion)
        }

        if isFavorite {
            upsertFavorite(image, market: market)
        } else {
            document.favorites.removeAll { $0.id == image.id }
        }

        try save()
    }

    public func toggleFavorite(_ image: BingImage, market: BingMarket) throws {
        try setFavorite(image, market: market, isFavorite: !isFavorite(id: image.id))
    }

    public func recordRecent(_ image: BingImage, market: BingMarket) throws {
        if let unsupportedVersion {
            throw WallpaperLibraryMutationError.unsupportedVersion(unsupportedVersion)
        }

        let recent = RecentWallpaper(
            snapshot: WallpaperSnapshot(image: image, market: market),
            setAt: now()
        )
        document.recentSet.removeAll { $0.id == recent.id }
        document.recentSet.insert(recent, at: 0)

        if document.recentSet.count > Self.recentLimit {
            document.recentSet.removeSubrange(Self.recentLimit...)
        }

        try save()
    }

    public func isFavorite(id: BingImage.ID) -> Bool {
        document.favorites.contains { $0.id == id }
    }

    public func favoriteIDs() -> Set<BingImage.ID> {
        Set(document.favorites.map(\.id))
    }

    public func pinnedCacheFileNames(resolutions: [WallpaperResolution] = WallpaperResolution.allCases) -> Set<String> {
        Set(
            document.favorites.flatMap { favorite in
                resolutions.map { resolution in
                    favorite.snapshot.image.fileName(resolution: resolution)
                }
            }
        )
    }

    private func upsertFavorite(_ image: BingImage, market: BingMarket) {
        let favorite = FavoriteWallpaper(
            snapshot: WallpaperSnapshot(image: image, market: market),
            favoritedAt: now()
        )

        if let index = document.favorites.firstIndex(where: { $0.id == favorite.id }) {
            document.favorites[index] = favorite
        } else {
            document.favorites.insert(favorite, at: 0)
        }
    }

    private func save() throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: [.atomic])
    }

    private func quarantineDamagedFile() -> WallpaperLibraryLoadIssue {
        let backupURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(fileURL.lastPathComponent).broken-\(Int(now().timeIntervalSince1970))")

        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.moveItem(at: fileURL, to: backupURL)
            return .damagedJSONBackupCreated(backupURL)
        } catch {
            return .damagedJSONBackupFailed
        }
    }

    private struct VersionedWallpaperLibraryDocument: Decodable {
        let version: Int
    }
}
