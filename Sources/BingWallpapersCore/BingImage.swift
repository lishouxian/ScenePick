import Foundation

public struct BingArchiveResponse: Decodable, Equatable, Sendable {
    public let images: [BingImage]
    public let tooltips: BingTooltips?
}

public struct BingTooltips: Decodable, Equatable, Sendable {
    public let loading: String?
    public let previous: String?
    public let next: String?
    public let walle: String?
    public let walls: String?
}

public struct BingImage: Decodable, Equatable, Hashable, Identifiable, Sendable {
    public let startDate: String
    public let fullStartDate: String?
    public let endDate: String?
    public let url: String
    public let urlBase: String
    public let copyright: String
    public let copyrightLink: String?
    public let title: String
    public let quiz: String?
    public let wp: Bool?
    public let hash: String?
    public let drk: Int?
    public let top: Int?
    public let bot: Int?

    public var id: String {
        [startDate, hash ?? urlBase].joined(separator: "-")
    }

    public var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "Bing Daily Wallpaper" : trimmedTitle
    }

    public var copyrightText: String {
        copyright.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var previewURL: URL {
        absoluteBingURL(for: url)
    }

    public func imageURL(resolution: WallpaperResolution) -> URL {
        switch resolution {
        case .uhd, .fullHD:
            guard !urlBase.isEmpty else {
                return previewURL
            }

            return absoluteBingURL(for: "\(urlBase)_\(resolution.bingSuffix).jpg")
        case .preview:
            return previewURL
        }
    }

    public func fileName(resolution: WallpaperResolution) -> String {
        let readableTitle = displayTitle
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(8)
            .joined(separator: "-")

        let base = readableTitle.isEmpty ? "bing-wallpaper" : readableTitle
        return "\(startDate)-\(resolution.fileToken)-\(base).jpg"
    }

    private func absoluteBingURL(for path: String) -> URL {
        if let url = URL(string: path), url.scheme != nil {
            return url
        }

        var normalizedPath = path
        if !normalizedPath.hasPrefix("/") {
            normalizedPath = "/" + normalizedPath
        }

        return URL(string: "https://www.bing.com\(normalizedPath)")!
    }

    private enum CodingKeys: String, CodingKey {
        case startDate = "startdate"
        case fullStartDate = "fullstartdate"
        case endDate = "enddate"
        case url
        case urlBase = "urlbase"
        case copyright
        case copyrightLink = "copyrightlink"
        case title
        case quiz
        case wp
        case hash = "hsh"
        case drk
        case top
        case bot
    }
}

public enum WallpaperResolution: String, CaseIterable, Codable, Identifiable, Sendable {
    case uhd = "UHD"
    case fullHD = "1920x1080"
    case preview = "Preview"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .uhd:
            return "UHD"
        case .fullHD:
            return "HD 1080p"
        case .preview:
            return "Preview"
        }
    }

    var bingSuffix: String {
        switch self {
        case .uhd:
            return "UHD"
        case .fullHD:
            return "1920x1080"
        case .preview:
            return "1366x768"
        }
    }

    var fileToken: String {
        switch self {
        case .uhd:
            return "uhd"
        case .fullHD:
            return "1080p"
        case .preview:
            return "preview"
        }
    }
}
