import Foundation

public final class WallpaperCache: @unchecked Sendable {
    private let fileManager: FileManager
    public let directory: URL

    public init(
        directory: URL = WallpaperCache.defaultDirectory,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.fileManager = fileManager
    }

    public static var defaultDirectory: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupport
            .appendingPathComponent("ScenePick", isDirectory: true)
            .appendingPathComponent("Cache", isDirectory: true)
    }

    public func cachedFileURL(for image: BingImage, resolution: WallpaperResolution) -> URL {
        directory.appendingPathComponent(image.fileName(resolution: resolution), isDirectory: false)
    }

    public func isCached(for image: BingImage, resolution: WallpaperResolution) -> Bool {
        fileManager.fileExists(atPath: cachedFileURL(for: image, resolution: resolution).path)
    }

    public func cachedImageURL(
        for image: BingImage,
        resolution: WallpaperResolution,
        session: URLSession = .shared
    ) async throws -> URL {
        let destination = cachedFileURL(for: image, resolution: resolution)
        if fileManager.fileExists(atPath: destination.path) {
            return destination
        }

        try ensureDirectoryExists()

        let sourceURL = image.imageURL(resolution: resolution)
        let (data, response) = try await session.data(from: sourceURL)
        try validateImageResponse(response, data: data)

        try data.write(to: destination, options: [.atomic])
        return destination
    }

    @discardableResult
    public func write(
        _ data: Data,
        for image: BingImage,
        resolution: WallpaperResolution
    ) throws -> URL {
        try ensureDirectoryExists()
        let destination = cachedFileURL(for: image, resolution: resolution)
        try data.write(to: destination, options: [.atomic])
        return destination
    }

    public func removeAll() throws {
        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }

        try fileManager.removeItem(at: directory)
    }

    private func ensureDirectoryExists() throws {
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    private func validateImageResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BingWallpaperError.badResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw BingWallpaperError.httpStatus(httpResponse.statusCode)
        }

        guard hasImageContentType(httpResponse) else {
            throw BingWallpaperError.invalidImageData
        }

        guard data.count > 4_096 else {
            throw BingWallpaperError.invalidImageData
        }

        guard hasSupportedImageSignature(data) else {
            throw BingWallpaperError.invalidImageData
        }
    }

    private func hasImageContentType(_ response: HTTPURLResponse) -> Bool {
        guard let contentType = response.value(forHTTPHeaderField: "Content-Type") else {
            return true
        }

        return contentType
            .lowercased()
            .split(separator: ";", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .hasPrefix("image/") == true
    }

    private func hasSupportedImageSignature(_ data: Data) -> Bool {
        hasJPEGSignature(data) || hasPNGSignature(data)
    }

    private func hasJPEGSignature(_ data: Data) -> Bool {
        let signature: [UInt8] = [0xFF, 0xD8, 0xFF]
        return data.starts(with: signature)
    }

    private func hasPNGSignature(_ data: Data) -> Bool {
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        return data.starts(with: signature)
    }

}
