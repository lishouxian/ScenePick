import BingWallpapersCore
import Foundation

@main
struct BingWallpapersCoreSelfTest {
    static func main() throws {
        try decodesBingArchiveAndBuildsHighResolutionURLs()
        try fileNameIsStableAndSafeForCache()
        try archiveURLUsesBingArchiveEndpointAndClampsCount()
        try writesCacheFileIntoConfiguredDirectory()
        try detectsCachedFiles()

        print("BingWallpapersCoreSelfTest: 5 tests passed")
    }

    private static func decodesBingArchiveAndBuildsHighResolutionURLs() throws {
        let archive = try JSONDecoder().decode(
            BingArchiveResponse.self,
            from: archiveFixture
        )

        let image = try require(archive.images.first, "archive should include one image")

        try expect(image.id == "20260503-fixturehash", "stable Bing image id")
        try expect(image.displayTitle == "Desert Geometry", "display title")
        try expect(
            image.previewURL.absoluteString == "https://global.bing.com/th?id=OHR.DesertGeometry_EN-US1234567890_1366x768.jpg&rf=LaDigue_1366x768.jpg&pid=hp",
            "preview URL"
        )
        try expect(
            image.imageURL(resolution: .uhd).absoluteString == "https://global.bing.com/th?id=OHR.DesertGeometry_EN-US1234567890_UHD.jpg",
            "UHD URL"
        )
        try expect(
            image.imageURL(resolution: .fullHD).absoluteString == "https://global.bing.com/th?id=OHR.DesertGeometry_EN-US1234567890_1920x1080.jpg",
            "1080p URL"
        )
    }

    private static func fileNameIsStableAndSafeForCache() throws {
        let image = try require(
            try JSONDecoder().decode(BingArchiveResponse.self, from: archiveFixture).images.first,
            "archive image"
        )
        let fileName = image.fileName(resolution: .uhd)

        try expect(fileName == "20260503-uhd-desert-geometry.jpg", "cache file name")
        try expect(!fileName.contains(" "), "cache file name should not contain spaces")
        try expect(!fileName.contains("/"), "cache file name should not contain slashes")
    }

    private static func archiveURLUsesBingArchiveEndpointAndClampsCount() throws {
        let url = try BingWallpaperService.archiveURL(
            market: .china,
            count: 25,
            offset: -4
        )
        let components = try require(
            URLComponents(url: url, resolvingAgainstBaseURL: false),
            "archive URL components"
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        try expect(components.scheme == "https", "archive URL scheme")
        try expect(components.host == "global.bing.com", "archive URL host")
        try expect(components.path == "/HPImageArchive.aspx", "archive URL path")
        try expect(queryItems["format"] == "js", "archive format query")
        try expect(queryItems["idx"] == "0", "archive offset clamp")
        try expect(queryItems["n"] == "8", "archive count clamp")
        try expect(queryItems["mkt"] == "zh-CN", "archive market query")
        try expect(queryItems["uhd"] == "1", "archive UHD query")
    }

    private static func writesCacheFileIntoConfiguredDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = WallpaperCache(directory: directory)
        let image = try require(
            try JSONDecoder().decode(BingArchiveResponse.self, from: cacheFixture).images.first,
            "cache fixture image"
        )

        let url = try cache.write(Data(repeating: 1, count: 8), for: image, resolution: .fullHD)

        try expect(FileManager.default.fileExists(atPath: url.path), "cache file should exist")
        try expect(url.deletingLastPathComponent() == directory, "cache file directory")

        try cache.removeAll()
        try expect(!FileManager.default.fileExists(atPath: directory.path), "cache directory should be removed")
    }

    private static func detectsCachedFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = WallpaperCache(directory: directory)
        let image = try require(
            try JSONDecoder().decode(BingArchiveResponse.self, from: cacheFixture).images.first,
            "cache fixture image"
        )

        try expect(!cache.isCached(for: image, resolution: .preview), "preview should not be cached before write")
        try cache.write(Data(repeating: 1, count: 8), for: image, resolution: .preview)
        try expect(cache.isCached(for: image, resolution: .preview), "preview should be cached after write")

        try cache.removeAll()
    }

    private static func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else {
            throw TestFailure(message)
        }

        return value
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw TestFailure(message)
        }
    }

    private struct TestFailure: Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }

    private static let archiveFixture = Data("""
    {
      "images": [
        {
          "startdate": "20260503",
          "url": "/th?id=OHR.DesertGeometry_EN-US1234567890_1366x768.jpg&rf=LaDigue_1366x768.jpg&pid=hp",
          "urlbase": "/th?id=OHR.DesertGeometry_EN-US1234567890",
          "copyright": "Sand dunes at sunrise (Example)",
          "copyrightlink": "https://www.bing.com/search?q=sand+dunes",
          "title": "Desert Geometry",
          "hsh": "fixturehash"
        }
      ]
    }
    """.utf8)

    private static let cacheFixture = Data("""
    {
      "images": [
        {
          "startdate": "20260503",
          "url": "/th?id=OHR.Test_1366x768.jpg",
          "urlbase": "/th?id=OHR.Test",
          "copyright": "Fixture",
          "copyrightlink": "https://www.bing.com/search?q=fixture",
          "title": "Fixture Image"
        }
      ]
    }
    """.utf8)
}
