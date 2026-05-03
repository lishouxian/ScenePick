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
            .appendingPathComponent("BingWallpaperSwitcher", isDirectory: true)
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
        session: URLSession = .shared,
        onProgress: WallpaperDownloadProgressHandler? = nil
    ) async throws -> URL {
        let destination = cachedFileURL(for: image, resolution: resolution)
        if fileManager.fileExists(atPath: destination.path) {
            await onProgress?(.complete)
            return destination
        }

        try ensureDirectoryExists()

        let sourceURL = image.imageURL(resolution: resolution)
        let (bytes, response) = try await session.bytes(from: sourceURL)
        let data = try await downloadData(from: bytes, response: response, onProgress: onProgress)
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

        guard data.count > 4_096 else {
            throw BingWallpaperError.invalidImageData
        }
    }

    private func downloadData(
        from bytes: URLSession.AsyncBytes,
        response: URLResponse,
        onProgress: WallpaperDownloadProgressHandler?
    ) async throws -> Data {
        let totalBytes = response.expectedContentLength > 0 ? response.expectedContentLength : nil
        var receivedBytes: Int64 = 0
        var data = Data()

        if let totalBytes {
            data.reserveCapacity(Int(min(totalBytes, Int64(Int.max))))
        }

        await onProgress?(WallpaperDownloadProgress(completedBytes: 0, totalBytes: totalBytes))

        for try await byte in bytes {
            try Task.checkCancellation()
            data.append(byte)
            receivedBytes += 1

            if receivedBytes % 65_536 == 0 {
                await onProgress?(
                    WallpaperDownloadProgress(
                        completedBytes: receivedBytes,
                        totalBytes: totalBytes
                    )
                )
            }
        }

        await onProgress?(
            WallpaperDownloadProgress(
                completedBytes: receivedBytes,
                totalBytes: totalBytes
            )
        )

        return data
    }
}

public typealias WallpaperDownloadProgressHandler = @MainActor (WallpaperDownloadProgress) -> Void

public struct WallpaperDownloadProgress: Equatable, Sendable {
    public let completedBytes: Int64
    public let totalBytes: Int64?

    public init(completedBytes: Int64, totalBytes: Int64?) {
        self.completedBytes = completedBytes
        self.totalBytes = totalBytes
    }

    public static var complete: WallpaperDownloadProgress {
        WallpaperDownloadProgress(completedBytes: 1, totalBytes: 1)
    }

    public var fractionCompleted: Double? {
        guard let totalBytes, totalBytes > 0 else {
            return nil
        }

        return min(1, max(0, Double(completedBytes) / Double(totalBytes)))
    }
}
