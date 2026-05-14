import BingWallpapersCore
import AppKit
import Foundation

@main
struct BingWallpapersCoreSelfTest {
    static func main() async throws {
        try decodesBingArchiveAndBuildsHighResolutionURLs()
        try usesCopyrightDescriptionWhenBingReturnsPlaceholderTitle()
        try fileNameIsStableAndSafeForCache()
        try fileNameIncludesImageIdentityToAvoidCrossMarketCollisions()
        try defaultArchiveSessionUsesShortRequestTimeout()
        try archiveURLUsesBingArchiveEndpointAndClampsCount()
        try archiveURLClampsOffsetToBingLimit()
        try await fetchAvailableArchiveCombinesLatestAndOlderImages()
        try await fetchAvailableArchiveFallsBackWhenOlderArchiveIsEmpty()
        try await fetchAvailableArchiveFallsBackWhenOlderArchiveReturnsHTTPError()
        try await fetchAvailableArchiveFallsBackWhenOlderArchiveFailsNetwork()
        try await fetchAvailableArchiveFallsBackWhenOlderArchiveCannotDecode()
        try await fetchAvailableArchivePropagatesOlderArchiveCancellation()
        try await fetchAvailableArchiveSkipsOlderRequestWhenLatestPageIsPartial()
        try await fetchAvailableArchivePropagatesLatestHTTPFailure()
        try await fetchAvailableArchivePropagatesLatestDecodeFailure()
        try setDesktopImageSucceedsAcrossAllScreens()
        try setDesktopImageAttemptsRemainingScreensAfterPartialFailure()
        try setDesktopImageThrowsSummaryWhenAllScreensFail()
        try setDesktopImageKeepsNoScreensErrorDistinct()
        try desktopPartialFailureErrorIsLocalized()
        try wallpaperLibraryStartsEmptyWhenFileMissing()
        try wallpaperLibraryPersistsFavoriteSnapshot()
        try wallpaperLibraryFavoriteMutationsStayUnique()
        try wallpaperLibraryRejectsUnknownVersionWithoutOverwriting()
        try wallpaperLibraryRejectsMutationAfterUnknownVersion()
        try wallpaperLibraryQuarantinesDamagedJSON()
        try wallpaperLibraryPinnedCacheFileNamesIncludeAllResolutions()
        try wallpaperSnapshotRestoresBingImageMetadata()
        try wallpaperSelectionFallsBackToFirstVisibleImage()
        try writesCacheFileIntoConfiguredDirectory()
        try detectsCachedFiles()
        try await acceptsJPEGImageResponse()
        try await acceptsPNGImageResponse()
        try await acceptsImageResponseWithoutContentType()
        try await rejectsHTMLImageResponse()
        try await rejectsHTMLDataWithImageContentType()
        try await rejectsSmallImageData()
        try await rejectsTruncatedImageSignature()
        try dailyUpdateRunsAfterScheduledTimeWhenNotRunToday()
        try dailyUpdateSkipsWhenAlreadyRunToday()
        try dailyUpdateCheckDelayIncludesClampedRandomOffset()

        print("BingWallpapersCoreSelfTest: 42 tests passed")
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

    private static func defaultArchiveSessionUsesShortRequestTimeout() throws {
        let session = BingWallpaperService.defaultSession()

        try expect(
            session.configuration.timeoutIntervalForRequest == BingWallpaperService.defaultRequestTimeout,
            "default Bing archive session should use explicit request timeout"
        )
        try expect(
            session.configuration.timeoutIntervalForRequest <= 15,
            "Bing archive request timeout should not use URLSession's default 60s"
        )
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

    private static func fetchAvailableArchiveCombinesLatestAndOlderImages() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8)),
                older: .json(archiveData(prefix: "older", count: 8))
            )
        )

        let images = try await service.fetchAvailableArchive(market: .china)

        try expect(images.count == 16, "available archive should combine latest and older pages")
    }

    private static func fetchAvailableArchiveFallsBackWhenOlderArchiveIsEmpty() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8)),
                older: .json(emptyArchiveData)
            )
        )

        let images = try await service.fetchAvailableArchive(market: .china)

        try expect(images.count == 8, "available archive should fall back to latest when older page is empty")
        try expect(images.allSatisfy { $0.id.contains("latest") }, "fallback images should come from latest page")
    }

    private static func fetchAvailableArchiveFallsBackWhenOlderArchiveReturnsHTTPError() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8)),
                older: .json(archiveData(prefix: "older", count: 8), statusCode: 500)
            )
        )

        let images = try await service.fetchAvailableArchive(market: .china)

        try expect(images.count == 8, "available archive should fall back to latest when older page returns HTTP error")
    }

    private static func fetchAvailableArchiveFallsBackWhenOlderArchiveFailsNetwork() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8)),
                older: .failure(URLError(.notConnectedToInternet))
            )
        )

        let images = try await service.fetchAvailableArchive(market: .china)

        try expect(images.count == 8, "available archive should fall back to latest when older page fails network")
    }

    private static func fetchAvailableArchiveFallsBackWhenOlderArchiveCannotDecode() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8)),
                older: .json(Data("not json".utf8))
            )
        )

        let images = try await service.fetchAvailableArchive(market: .china)

        try expect(images.count == 8, "available archive should fall back to latest when older page cannot decode")
    }

    private static func fetchAvailableArchivePropagatesOlderArchiveCancellation() async throws {
        URLProtocolStub.reset()
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8)),
                older: .neverCompletes()
            )
        )
        let task = Task {
            try await service.fetchAvailableArchive(market: .china)
        }

        var attempts = 0
        while !URLProtocolStub.requestedOffsets.contains("7") {
            guard attempts < 100 else {
                throw TestFailure("available archive should request older page before cancellation")
            }
            attempts += 1
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        task.cancel()

        do {
            _ = try await task.value
            throw TestFailure("available archive should propagate older page cancellation")
        } catch is CancellationError {
        } catch {
            try expect((error as? URLError)?.code == .cancelled, "available archive should propagate URL cancellation")
        }
    }

    private static func fetchAvailableArchiveSkipsOlderRequestWhenLatestPageIsPartial() async throws {
        URLProtocolStub.reset()
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 3)),
                older: .json(archiveData(prefix: "older", count: 8))
            )
        )

        let images = try await service.fetchAvailableArchive(market: .china)

        try expect(images.count == 3, "available archive should return partial latest page directly")
        try expect(URLProtocolStub.requestedOffsets == ["0"], "available archive should not request older page after partial latest page")
    }

    private static func fetchAvailableArchivePropagatesLatestHTTPFailure() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(archiveData(prefix: "latest", count: 8), statusCode: 500),
                older: .json(archiveData(prefix: "older", count: 8))
            )
        )

        do {
            _ = try await service.fetchAvailableArchive(market: .china)
            throw TestFailure("available archive should propagate latest page HTTP failure")
        } catch BingWallpaperError.httpStatus(500) {
        }
    }

    private static func fetchAvailableArchivePropagatesLatestDecodeFailure() async throws {
        let service = BingWallpaperService(
            session: URLSession.stubbedArchive(
                latest: .json(Data("not json".utf8)),
                older: .json(archiveData(prefix: "older", count: 8))
            )
        )

        do {
            _ = try await service.fetchAvailableArchive(market: .china)
            throw TestFailure("available archive should propagate latest page failure")
        } catch is DecodingError {
        }
    }

    private static func setDesktopImageSucceedsAcrossAllScreens() throws {
        let fileURL = try temporaryWallpaperFile()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let perScreenSetter = RecordingPerScreenWallpaperSetter()
        let setter = MacDesktopWallpaperSetter(
            screenEnumerator: FixedScreenEnumerator(tokens: ["display-1", "display-2"]),
            perScreenSetter: perScreenSetter
        )

        try setter.setDesktopImage(fileURL: fileURL, fillMode: .fitScreen)

        try expect(perScreenSetter.attemptedTokens == ["display-1", "display-2"], "desktop setter should attempt every screen")
    }

    private static func setDesktopImageAttemptsRemainingScreensAfterPartialFailure() throws {
        let fileURL = try temporaryWallpaperFile()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let perScreenSetter = RecordingPerScreenWallpaperSetter(failingTokens: ["display-2"])
        let setter = MacDesktopWallpaperSetter(
            screenEnumerator: FixedScreenEnumerator(tokens: ["display-1", "display-2", "display-3"]),
            perScreenSetter: perScreenSetter
        )

        do {
            try setter.setDesktopImage(fileURL: fileURL)
            throw TestFailure("desktop setter should throw when one screen fails")
        } catch BingWallpaperError.someScreensFailed(let succeeded, let total) {
            try expect(succeeded == 2, "partial desktop failure should report succeeded screens")
            try expect(total == 3, "partial desktop failure should report total screens")
        }
        try expect(
            perScreenSetter.attemptedTokens == ["display-1", "display-2", "display-3"],
            "desktop setter should continue after a per-screen failure"
        )
    }

    private static func setDesktopImageThrowsSummaryWhenAllScreensFail() throws {
        let fileURL = try temporaryWallpaperFile()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let perScreenSetter = RecordingPerScreenWallpaperSetter(failingTokens: ["display-1", "display-2"])
        let setter = MacDesktopWallpaperSetter(
            screenEnumerator: FixedScreenEnumerator(tokens: ["display-1", "display-2"]),
            perScreenSetter: perScreenSetter
        )

        do {
            try setter.setDesktopImage(fileURL: fileURL)
            throw TestFailure("desktop setter should throw when every screen fails")
        } catch BingWallpaperError.someScreensFailed(let succeeded, let total) {
            try expect(succeeded == 0, "all-screen desktop failure should report zero successes")
            try expect(total == 2, "all-screen desktop failure should report total screens")
        }
        try expect(perScreenSetter.attemptedTokens == ["display-1", "display-2"], "desktop setter should attempt every failing screen")
    }

    private static func setDesktopImageKeepsNoScreensErrorDistinct() throws {
        let fileURL = try temporaryWallpaperFile()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let setter = MacDesktopWallpaperSetter(
            screenEnumerator: FixedScreenEnumerator(tokens: []),
            perScreenSetter: RecordingPerScreenWallpaperSetter()
        )

        do {
            try setter.setDesktopImage(fileURL: fileURL)
            throw TestFailure("desktop setter should throw when no screens are available")
        } catch BingWallpaperError.noScreensAvailable {
        }
    }

    private static func desktopPartialFailureErrorIsLocalized() throws {
        let store = BingWallpaperDefaults.store
        let key = BingWallpaperDefaultKeys.selectedLanguage
        let originalLanguage = store.string(forKey: key)
        defer {
            if let originalLanguage {
                store.set(originalLanguage, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }

        store.set("en", forKey: key)
        try expect(
            BingWallpaperError.someScreensFailed(succeeded: 1, total: 2).errorDescription == "Set wallpaper on 1 of 2 screens; the remaining screens failed.",
            "English partial screen failure error"
        )

        store.set("zh-Hans", forKey: key)
        try expect(
            BingWallpaperError.someScreensFailed(succeeded: 1, total: 2).errorDescription == "已为 1/2 个屏幕设置壁纸，其余屏幕设置失败。",
            "Chinese partial screen failure error"
        )
    }

    @MainActor
    private static func wallpaperLibraryStartsEmptyWhenFileMissing() throws {
        let fileURL = temporaryLibraryFileURL()
        let store = JSONWallpaperLibraryStore(fileURL: fileURL)

        store.load()

        try expect(store.document == .empty, "missing wallpaper library should load an empty document")
        try expect(store.loadIssue == nil, "missing wallpaper library should not report a load issue")
    }

    @MainActor
    private static func wallpaperLibraryPersistsFavoriteSnapshot() throws {
        let fileURL = temporaryLibraryFileURL()
        let image = try cacheFixtureImage()
        let store = JSONWallpaperLibraryStore(fileURL: fileURL, now: fixedLibraryDate)

        try store.setFavorite(image, market: .china, isFavorite: true)

        let reloadedStore = JSONWallpaperLibraryStore(fileURL: fileURL)
        reloadedStore.load()

        let favorite = try require(reloadedStore.document.favorites.first, "persisted favorite")
        try expect(favorite.id == image.id, "favorite ID should persist")
        try expect(favorite.snapshot.market == .china, "favorite market should persist")
        try expect(favorite.snapshot.title == image.title, "favorite title snapshot should persist")
        try expect(favorite.favoritedAt == fixedLibraryDate(), "favorite timestamp should persist")
    }

    @MainActor
    private static func wallpaperLibraryFavoriteMutationsStayUnique() throws {
        let fileURL = temporaryLibraryFileURL()
        let image = try cacheFixtureImage()
        let store = JSONWallpaperLibraryStore(fileURL: fileURL)

        try store.setFavorite(image, market: .china, isFavorite: true)
        try store.setFavorite(image, market: .china, isFavorite: true)
        try expect(store.document.favorites.count == 1, "setting the same favorite twice should not duplicate it")

        try store.toggleFavorite(image, market: .china)
        try expect(!store.isFavorite(id: image.id), "toggle should remove an existing favorite")

        try store.setFavorite(image, market: .china, isFavorite: true)
        try expect(store.isFavorite(id: image.id), "last favorite mutation should win")
    }

    @MainActor
    private static func wallpaperLibraryRejectsUnknownVersionWithoutOverwriting() throws {
        let fileURL = temporaryLibraryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let originalData = Data("""
        {
          "version": 99,
          "favorites": [],
          "recentSet": []
        }
        """.utf8)
        try originalData.write(to: fileURL)

        let store = JSONWallpaperLibraryStore(fileURL: fileURL)
        store.load()

        try expect(store.document == .empty, "unknown library version should fall back to an empty document")
        try expect(store.loadIssue == .unsupportedVersion(99), "unknown library version should be reported")
        let reloadedData = try Data(contentsOf: fileURL)
        try expect(reloadedData == originalData, "unknown version file should not be overwritten")
    }

    @MainActor
    private static func wallpaperLibraryRejectsMutationAfterUnknownVersion() throws {
        let fileURL = temporaryLibraryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let originalData = Data("""
        {
          "version": 99,
          "favorites": [
            {
              "snapshot": {
                "id": "future-id",
                "startDate": "20260514",
                "market": "zh-CN",
                "title": "Future",
                "copyright": "Future copyright",
                "copyrightLink": null,
                "url": "/th?id=OHR.Future_1366x768.jpg",
                "urlBase": "/th?id=OHR.Future",
                "hash": "future-hash"
              },
              "favoritedAt": "2026-05-14T00:00:00Z"
            }
          ],
          "recentSet": []
        }
        """.utf8)
        try originalData.write(to: fileURL)

        let store = JSONWallpaperLibraryStore(fileURL: fileURL)
        store.load()

        do {
            try store.setFavorite(try cacheFixtureImage(), market: .china, isFavorite: true)
            throw TestFailure("unknown version library should reject favorite mutations")
        } catch WallpaperLibraryMutationError.unsupportedVersion(99) {
        }

        let reloadedData = try Data(contentsOf: fileURL)
        try expect(reloadedData == originalData, "unknown version mutation should not overwrite original bytes")
    }

    @MainActor
    private static func wallpaperLibraryQuarantinesDamagedJSON() throws {
        let fileURL = temporaryLibraryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let damagedData = Data("{".utf8)
        try damagedData.write(to: fileURL)

        let store = JSONWallpaperLibraryStore(fileURL: fileURL, now: fixedLibraryDate)
        store.load()

        try expect(store.document == .empty, "damaged library should fall back to an empty document")
        guard case .damagedJSONBackupCreated(let backupURL) = store.loadIssue else {
            throw TestFailure("damaged library should report a backup URL")
        }
        try expect(!FileManager.default.fileExists(atPath: fileURL.path), "damaged library should be moved away from the active path")
        let backupData = try Data(contentsOf: backupURL)
        try expect(backupData == damagedData, "damaged library backup should preserve original bytes")
    }

    @MainActor
    private static func wallpaperLibraryPinnedCacheFileNamesIncludeAllResolutions() throws {
        let fileURL = temporaryLibraryFileURL()
        let image = try cacheFixtureImage()
        let store = JSONWallpaperLibraryStore(fileURL: fileURL)

        try store.setFavorite(image, market: .china, isFavorite: true)

        try expect(
            store.pinnedCacheFileNames(resolutions: WallpaperResolution.allCases) == Set(WallpaperResolution.allCases.map { image.fileName(resolution: $0) }),
            "pinned file names should cover every requested resolution"
        )
    }

    @MainActor
    private static func wallpaperSnapshotRestoresBingImageMetadata() throws {
        let image = try cacheFixtureImage()
        let snapshot = WallpaperSnapshot(image: image, market: .australia)
        let restoredImage = snapshot.image

        try expect(snapshot.id == image.id, "snapshot should retain image identity")
        try expect(restoredImage == image, "snapshot should restore a BingImage for cache and preview reuse")
        try expect(snapshot.market == .australia, "snapshot should retain market context")
    }

    private static func wallpaperSelectionFallsBackToFirstVisibleImage() throws {
        let archiveImage = try cacheFixtureImage()
        let favoriteSnapshotImage = BingImage(
            startDate: "20260514",
            url: "/th?id=OHR.FavoriteOnly_1366x768.jpg",
            urlBase: "/th?id=OHR.FavoriteOnly",
            copyright: "Favorite-only fixture",
            copyrightLink: nil,
            title: "Favorite Only",
            hash: "favorite-only-hash"
        )

        let selectedImage = BingImageSelection.selectedImage(
            in: [favoriteSnapshotImage],
            selectedID: archiveImage.id
        )

        try expect(
            selectedImage?.id == favoriteSnapshotImage.id,
            "favorite filter should fall back to the first snapshot when selected ID belongs to the archive list"
        )
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

    private static func acceptsJPEGImageResponse() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = WallpaperCache(directory: directory)
        let image = try cacheFixtureImage()
        let url = try await cache.cachedImageURL(
            for: image,
            resolution: .preview,
            session: URLSession.stubbed(
                data: jpegImageData(),
                contentType: "image/jpeg"
            )
        )

        try expect(FileManager.default.fileExists(atPath: url.path), "JPEG image response should be cached")
        try cache.removeAll()
    }

    private static func acceptsPNGImageResponse() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = WallpaperCache(directory: directory)
        let image = try cacheFixtureImage()
        let url = try await cache.cachedImageURL(
            for: image,
            resolution: .preview,
            session: URLSession.stubbed(
                data: pngImageData(),
                contentType: "image/png; charset=binary"
            )
        )

        try expect(FileManager.default.fileExists(atPath: url.path), "PNG image response should be cached")
        try cache.removeAll()
    }

    private static func acceptsImageResponseWithoutContentType() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = WallpaperCache(directory: directory)
        let image = try cacheFixtureImage()
        let url = try await cache.cachedImageURL(
            for: image,
            resolution: .preview,
            session: URLSession.stubbed(data: jpegImageData())
        )

        try expect(FileManager.default.fileExists(atPath: url.path), "image response without content type should be cached")
        try cache.removeAll()
    }

    private static func rejectsHTMLImageResponse() async throws {
        try await expectInvalidImageData(
            data: htmlData(),
            contentType: "text/html",
            message: "HTML response should not be cached"
        )
    }

    private static func rejectsHTMLDataWithImageContentType() async throws {
        try await expectInvalidImageData(
            data: htmlData(),
            contentType: "image/jpeg",
            message: "HTML data with image content type should not be cached"
        )
    }

    private static func rejectsSmallImageData() async throws {
        try await expectInvalidImageData(
            data: Data([0xFF, 0xD8, 0xFF, 0xD9]),
            contentType: "image/jpeg",
            message: "small image data should not be cached"
        )
    }

    private static func rejectsTruncatedImageSignature() async throws {
        var data = Data([0xFF, 0xD8])
        data.append(Data(repeating: 0, count: 4_200))

        try await expectInvalidImageData(
            data: data,
            contentType: "image/jpeg",
            message: "truncated image signature should not be cached"
        )
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

    private static func expectInvalidImageData(
        data: Data,
        contentType: String?,
        message: String
    ) async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = WallpaperCache(directory: directory)
        let image = try cacheFixtureImage()
        let destination = cache.cachedFileURL(for: image, resolution: .preview)

        do {
            _ = try await cache.cachedImageURL(
                for: image,
                resolution: .preview,
                session: URLSession.stubbed(data: data, contentType: contentType)
            )
            throw TestFailure(message)
        } catch BingWallpaperError.invalidImageData {
            try expect(!FileManager.default.fileExists(atPath: destination.path), "\(message): invalid data should not be written")
            try? cache.removeAll()
        }
    }

    private static func cacheFixtureImage() throws -> BingImage {
        try require(
            try JSONDecoder().decode(BingArchiveResponse.self, from: cacheFixture).images.first,
            "cache fixture image"
        )
    }

    private static func jpegImageData() -> Data {
        var data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        data.append(Data(repeating: 0, count: 4_200))
        return data
    }

    private static func pngImageData() -> Data {
        var data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        data.append(Data(repeating: 0, count: 4_200))
        return data
    }

    private static func htmlData() -> Data {
        var data = Data("<!doctype html><html><body>Sign in</body></html>".utf8)
        data.append(Data(repeating: 0x20, count: 4_200))
        return data
    }

    private static func temporaryWallpaperFile() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("wallpaper.jpg")
        try Data(repeating: 1, count: 8).write(to: fileURL)
        return fileURL
    }

    private static func temporaryLibraryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("wallpapers.json", isDirectory: false)
    }

    private static func fixedLibraryDate() -> Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    private static func archiveData(prefix: String, count: Int) -> Data {
        let images = (0..<count).map { index in
            """
            {
              "startdate": "202605\(String(format: "%02d", index + 1))",
              "url": "/th?id=OHR.\(prefix)\(index)_1366x768.jpg",
              "urlbase": "/th?id=OHR.\(prefix)\(index)",
              "copyright": "\(prefix) fixture \(index)",
              "copyrightlink": "https://www.bing.com/search?q=\(prefix)\(index)",
              "title": "\(prefix) \(index)",
              "hsh": "\(prefix)-hash-\(index)"
            }
            """
        }
        .joined(separator: ",")

        return Data("""
        {
          "images": [
            \(images)
          ]
        }
        """.utf8)
    }

    private static let emptyArchiveData = Data("""
    {
      "images": []
    }
    """.utf8)

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

    private struct FixedScreen: DesktopScreenTarget {
        let identityToken: AnyHashable
    }

    private struct FixedScreenEnumerator: DesktopScreenEnumerating {
        let screens: [any DesktopScreenTarget]

        init(tokens: [AnyHashable]) {
            screens = tokens.map { FixedScreen(identityToken: $0) }
        }

        func availableScreens() -> [any DesktopScreenTarget] {
            screens
        }
    }

    private final class RecordingPerScreenWallpaperSetter: PerScreenWallpaperSetting {
        private let failingTokens: Set<AnyHashable>
        private(set) var attemptedTokens: [AnyHashable] = []

        init(failingTokens: Set<AnyHashable> = []) {
            self.failingTokens = failingTokens
        }

        func setDesktopImage(
            fileURL: URL,
            on screen: any DesktopScreenTarget,
            options: [NSWorkspace.DesktopImageOptionKey: Any]
        ) throws {
            attemptedTokens.append(screen.identityToken)
            if failingTokens.contains(screen.identityToken) {
                throw TestFailure("screen failed: \(screen.identityToken)")
            }
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

private final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var defaultResponse = StubbedResponse(data: Data())
    nonisolated(unsafe) static var responsesByOffset: [String: StubbedResponse] = [:]
    nonisolated(unsafe) static var requestedOffsets: [String] = []

    static func reset() {
        defaultResponse = StubbedResponse(data: Data())
        responsesByOffset = [:]
        requestedOffsets = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let offset = request.url
            .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?
            .first { $0.name == "idx" }?
            .value ?? "default"
        Self.requestedOffsets.append(offset)

        let stubbedResponse = Self.responsesByOffset[offset] ?? Self.defaultResponse
        if let error = stubbedResponse.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if stubbedResponse.neverCompletes {
            return
        }

        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: stubbedResponse.statusCode,
            httpVersion: nil,
            headerFields: stubbedResponse.contentType.map { ["Content-Type": $0] }
        )!

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stubbedResponse.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct StubbedResponse {
    let data: Data
    let statusCode: Int
    let contentType: String?
    let error: Error?
    let neverCompletes: Bool

    init(
        data: Data,
        statusCode: Int = 200,
        contentType: String? = nil,
        error: Error? = nil,
        neverCompletes: Bool = false
    ) {
        self.data = data
        self.statusCode = statusCode
        self.contentType = contentType
        self.error = error
        self.neverCompletes = neverCompletes
    }

    static func json(
        _ data: Data,
        statusCode: Int = 200
    ) -> StubbedResponse {
        StubbedResponse(
            data: data,
            statusCode: statusCode,
            contentType: "application/json",
            error: nil
        )
    }

    static func image(
        _ data: Data,
        contentType: String? = nil
    ) -> StubbedResponse {
        StubbedResponse(
            data: data,
            statusCode: 200,
            contentType: contentType,
            error: nil
        )
    }

    static func failure(_ error: Error) -> StubbedResponse {
        StubbedResponse(
            data: Data(),
            statusCode: 200,
            contentType: nil,
            error: error
        )
    }

    static func neverCompletes() -> StubbedResponse {
        StubbedResponse(
            data: Data(),
            neverCompletes: true
        )
    }
}

private extension URLSession {
    static func stubbed(data: Data, contentType: String? = nil) -> URLSession {
        URLProtocolStub.reset()
        URLProtocolStub.defaultResponse = .image(data, contentType: contentType)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    static func stubbedArchive(
        latest: StubbedResponse,
        older: StubbedResponse
    ) -> URLSession {
        URLProtocolStub.reset()
        URLProtocolStub.responsesByOffset = [
            "0": latest,
            "7": older
        ]

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}
