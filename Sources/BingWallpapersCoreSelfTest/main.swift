import BingWallpapersCore
import Foundation

@main
struct BingWallpapersCoreSelfTest {
    static func main() throws {
        try decodesBingArchiveAndBuildsHighResolutionURLs()
        try usesCopyrightDescriptionWhenBingReturnsPlaceholderTitle()
        try fileNameIsStableAndSafeForCache()
        try fileNameIncludesImageIdentityToAvoidCrossMarketCollisions()
        try archiveURLUsesBingArchiveEndpointAndClampsCount()
        try archiveURLClampsOffsetToBingLimit()
        try writesCacheFileIntoConfiguredDirectory()
        try detectsCachedFiles()
        try dailyUpdateRunsAfterScheduledTimeWhenNotRunToday()
        try dailyUpdateSkipsWhenAlreadyRunToday()
        try dailyUpdateCheckDelayIncludesClampedRandomOffset()

        print("BingWallpapersCoreSelfTest: 11 tests passed")
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

        try expect(fileName == "20260503-uhd-fixturehash-desert-geometry.jpg", "cache file name")
        try expect(!fileName.contains(" "), "cache file name should not contain spaces")
        try expect(!fileName.contains("/"), "cache file name should not contain slashes")
    }

    private static func usesCopyrightDescriptionWhenBingReturnsPlaceholderTitle() throws {
        let image = try require(
            try JSONDecoder().decode(BingArchiveResponse.self, from: australianTitleFixture).images.first,
            "Australian archive image"
        )

        try expect(
            image.displayTitle == "Leopard sleeping in a tree in the savannah, Masai Mara National Reserve, Kenya",
            "placeholder title fallback"
        )
    }

    private static func fileNameIncludesImageIdentityToAvoidCrossMarketCollisions() throws {
        let archive = try JSONDecoder().decode(
            BingArchiveResponse.self,
            from: crossMarketCollisionFixture
        )

        let first = try require(archive.images.first, "first archive image")
        let second = try require(archive.images.dropFirst().first, "second archive image")

        try expect(first.fileName(resolution: .preview) != second.fileName(resolution: .preview), "cache file names should not collide")
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

    private static func archiveURLClampsOffsetToBingLimit() throws {
        let url = try BingWallpaperService.archiveURL(
            market: .china,
            count: 8,
            offset: 30
        )
        let components = try require(
            URLComponents(url: url, resolvingAgainstBaseURL: false),
            "archive URL components"
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        try expect(queryItems["idx"] == "7", "archive offset upper clamp")
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

    private static func dailyUpdateRunsAfterScheduledTimeWhenNotRunToday() throws {
        let schedule = DailyAutoUpdateSchedule(calendar: utcCalendar)
        let now = utcDate(year: 2026, month: 5, day: 7, hour: 0, minute: 5)
        let yesterday = utcDate(year: 2026, month: 5, day: 6, hour: 9, minute: 0)

        try expect(schedule.shouldRun(now: now, lastRun: nil), "daily update should run after scheduled time")
        try expect(schedule.shouldRun(now: now, lastRun: yesterday), "daily update should recover when the prior day ran")
    }

    private static func dailyUpdateSkipsWhenAlreadyRunToday() throws {
        let schedule = DailyAutoUpdateSchedule(calendar: utcCalendar)
        let now = utcDate(year: 2026, month: 5, day: 7, hour: 1, minute: 0)
        let today = utcDate(year: 2026, month: 5, day: 7, hour: 0, minute: 5)

        try expect(!schedule.shouldRun(now: now, lastRun: today), "daily update should only run once per day")
    }

    private static func dailyUpdateCheckDelayIncludesClampedRandomOffset() throws {
        let schedule = DailyAutoUpdateSchedule(
            checkInterval: 300,
            maximumRandomOffset: 60,
            calendar: utcCalendar
        )

        try expect(schedule.nextCheckDelay(randomOffset: 17) == 317, "daily update check delay should include random offset")
        try expect(schedule.nextCheckDelay(randomOffset: -4) == 300, "daily update random offset should not reduce interval")
        try expect(schedule.nextCheckDelay(randomOffset: 120) == 360, "daily update random offset should be capped")
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

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func utcDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = utcCalendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date!
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

    private static let australianTitleFixture = Data("""
    {
      "images": [
        {
          "startdate": "20260503",
          "url": "/th?id=OHR.MasaiLeopard_ROW2641665263_UHD.jpg&rf=LaDigue_UHD.jpg&pid=hp&w=1920&h=1080&rs=1&c=4",
          "urlbase": "/th?id=OHR.MasaiLeopard_ROW2641665263",
          "copyright": "Leopard sleeping in a tree in the savannah, Masai Mara National Reserve, Kenya (© Klein & Hubert/Nature Picture Library)",
          "copyrightlink": "https://www.bing.com/search?q=Masai+Mara+National+Reserve&form=hpcapt",
          "title": "Info",
          "hsh": "3692b86299a509b1ab9c5aa8f722b0a6"
        }
      ]
    }
    """.utf8)

    private static let crossMarketCollisionFixture = Data("""
    {
      "images": [
        {
          "startdate": "20260503",
          "url": "/th?id=OHR.SharedTitle_EN-US1234567890_1366x768.jpg",
          "urlbase": "/th?id=OHR.SharedTitle_EN-US1234567890",
          "copyright": "US fixture",
          "copyrightlink": "https://www.bing.com/search?q=fixture",
          "title": "Shared Title"
        },
        {
          "startdate": "20260503",
          "url": "/th?id=OHR.SharedTitle_EN-GB1234567890_1366x768.jpg",
          "urlbase": "/th?id=OHR.SharedTitle_EN-GB1234567890",
          "copyright": "UK fixture",
          "copyrightlink": "https://www.bing.com/search?q=fixture",
          "title": "Shared Title"
        }
      ]
    }
    """.utf8)
}
