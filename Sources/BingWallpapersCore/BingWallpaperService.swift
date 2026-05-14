import Foundation

public final class BingWallpaperService: @unchecked Sendable {
    public static let archivePageSize = 8
    public static let maximumArchiveOffset = 7
    public static let defaultRequestTimeout: TimeInterval = 12

    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = BingWallpaperService.defaultSession(), decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    public static func defaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = defaultRequestTimeout
        return URLSession(configuration: configuration)
    }

    public func fetchArchive(
        market: BingMarket,
        count: Int = 8,
        offset: Int = 0
    ) async throws -> [BingImage] {
        let archiveURL = try Self.archiveURL(market: market, count: count, offset: offset)
        let (data, response) = try await session.data(from: archiveURL)
        try validate(response: response)

        let archive = try decoder.decode(BingArchiveResponse.self, from: data)
        guard !archive.images.isEmpty else {
            throw BingWallpaperError.emptyArchive
        }

        return archive.images
    }

    public func fetchAvailableArchive(market: BingMarket) async throws -> [BingImage] {
        let latestImages = try await fetchArchive(
            market: market,
            count: Self.archivePageSize
        )
        guard latestImages.count == Self.archivePageSize else {
            return latestImages
        }

        do {
            let olderImages = try await fetchArchive(
                market: market,
                count: Self.archivePageSize,
                offset: Self.maximumArchiveOffset
            )
            return Self.deduplicated(latestImages + olderImages)
        } catch {
            if Task.isCancelled {
                throw error
            }

            return latestImages
        }
    }

    public static func archiveURL(
        market: BingMarket,
        count: Int = 8,
        offset: Int = 0
    ) throws -> URL {
        var components = URLComponents(string: "https://global.bing.com/HPImageArchive.aspx")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "js"),
            URLQueryItem(name: "idx", value: String(min(max(offset, 0), maximumArchiveOffset))),
            URLQueryItem(name: "n", value: String(min(max(count, 1), archivePageSize))),
            URLQueryItem(name: "mkt", value: market.rawValue),
            URLQueryItem(name: "uhd", value: "1")
        ]

        guard let url = components?.url else {
            throw BingWallpaperError.invalidURL
        }

        return url
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BingWallpaperError.badResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw BingWallpaperError.httpStatus(httpResponse.statusCode)
        }
    }

    private static func deduplicated(_ images: [BingImage]) -> [BingImage] {
        var seenIDs = Set<BingImage.ID>()
        return images.filter { image in
            seenIDs.insert(image.id).inserted
        }
    }
}

public enum BingWallpaperError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case badResponse
    case httpStatus(Int)
    case emptyArchive
    case invalidImageData
    case missingCachedFile(URL)
    case noScreensAvailable

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return CoreL10n.string("error.invalidURL")
        case .badResponse:
            return CoreL10n.string("error.badResponse")
        case .httpStatus(let statusCode):
            return CoreL10n.format("error.httpStatus", statusCode)
        case .emptyArchive:
            return CoreL10n.string("error.emptyArchive")
        case .invalidImageData:
            return CoreL10n.string("error.invalidImageData")
        case .missingCachedFile(let url):
            return CoreL10n.format("error.missingCachedFile", url.path)
        case .noScreensAvailable:
            return CoreL10n.string("error.noScreensAvailable")
        }
    }
}
