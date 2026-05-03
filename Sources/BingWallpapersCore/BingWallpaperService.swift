import Foundation

public final class BingWallpaperService: @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
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

    public static func archiveURL(
        market: BingMarket,
        count: Int = 8,
        offset: Int = 0
    ) throws -> URL {
        var components = URLComponents(string: "https://global.bing.com/HPImageArchive.aspx")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "js"),
            URLQueryItem(name: "idx", value: String(max(0, offset))),
            URLQueryItem(name: "n", value: String(min(max(count, 1), 8))),
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
            return "Could not build a valid Bing wallpaper URL."
        case .badResponse:
            return "Bing returned an invalid response."
        case .httpStatus(let statusCode):
            return "Bing returned HTTP \(statusCode)."
        case .emptyArchive:
            return "Bing did not return any wallpapers."
        case .invalidImageData:
            return "Downloaded wallpaper data was not a valid image."
        case .missingCachedFile(let url):
            return "The wallpaper file was not found at \(url.path)."
        case .noScreensAvailable:
            return "No macOS screens were available for wallpaper switching."
        }
    }
}
