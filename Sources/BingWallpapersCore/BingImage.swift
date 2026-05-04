import Foundation

public struct BingArchiveResponse: Decodable, Equatable, Sendable {
    public let images: [BingImage]
}

public struct BingImage: Decodable, Equatable, Hashable, Identifiable, Sendable {
    public let startDate: String
    public let url: String
    public let urlBase: String
    public let copyright: String
    public let copyrightLink: String?
    public let title: String
    public let hash: String?

    public var id: String {
        [startDate, imageIdentitySource].joined(separator: "-")
    }

    public var displayTitle: String {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isPlaceholderTitle else {
            return copyrightDisplayTitle
        }

        return normalizedTitle
    }

    public var copyrightText: String {
        copyright.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var copyrightDisplayTitle: String {
        let normalizedCopyright = copyrightText
        guard !normalizedCopyright.isEmpty else {
            return ""
        }

        if let attributionRange = normalizedCopyright.range(of: " (©") {
            return String(normalizedCopyright[..<attributionRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return normalizedCopyright
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
        return "\(startDate)-\(resolution.fileToken)-\(safeFileToken(from: imageIdentitySource))-\(base).jpg"
    }

    private var imageIdentitySource: String {
        if let hash, !hash.isEmpty {
            return hash
        }

        if let bingImageID {
            return bingImageID
        }

        return urlBase
    }

    private var bingImageID: String? {
        guard let components = URLComponents(
            url: absoluteBingURL(for: urlBase),
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        return components.queryItems?
            .first { $0.name == "id" }?
            .value
            .flatMap { $0.isEmpty ? nil : $0 }
    }

    private func safeFileToken(from value: String) -> String {
        let token = value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return token.isEmpty ? "bing-image" : String(token.prefix(72))
    }

    private func absoluteBingURL(for path: String) -> URL {
        if let url = URL(string: path), url.scheme != nil {
            return url
        }

        var normalizedPath = path
        if !normalizedPath.hasPrefix("/") {
            normalizedPath = "/" + normalizedPath
        }

        return URL(string: "https://global.bing.com\(normalizedPath)")!
    }

    private enum CodingKeys: String, CodingKey {
        case startDate = "startdate"
        case url
        case urlBase = "urlbase"
        case copyright
        case copyrightLink = "copyrightlink"
        case title
        case hash = "hsh"
    }
}

private extension String {
    var isPlaceholderTitle: Bool {
        caseInsensitiveCompare("info") == .orderedSame
    }
}

public enum WallpaperResolution: String, CaseIterable, Codable, Identifiable, Sendable {
    case uhd = "UHD"
    case fullHD = "1920x1080"
    case preview = "Preview"

    public var id: String { rawValue }

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
