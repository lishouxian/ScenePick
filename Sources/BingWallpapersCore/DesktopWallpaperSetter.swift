import AppKit
import Foundation

public protocol DesktopWallpaperSetting {
    func setDesktopImage(fileURL: URL, fillMode: WallpaperFillMode) throws
}

public final class MacDesktopWallpaperSetter: DesktopWallpaperSetting {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func setDesktopImage(
        fileURL: URL,
        fillMode: WallpaperFillMode = .fillScreen
    ) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw BingWallpaperError.missingCachedFile(fileURL)
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw BingWallpaperError.noScreensAvailable
        }

        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: fillMode.imageScaling.rawValue,
            .allowClipping: fillMode.allowClipping
        ]

        for screen in screens {
            try NSWorkspace.shared.setDesktopImageURL(
                fileURL,
                for: screen,
                options: options
            )
        }
    }
}

public enum WallpaperFillMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case fillScreen
    case fitScreen

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .fillScreen:
            return "Fill Screen"
        case .fitScreen:
            return "Fit Screen"
        }
    }

    var imageScaling: NSImageScaling {
        switch self {
        case .fillScreen:
            return .scaleProportionallyUpOrDown
        case .fitScreen:
            return .scaleProportionallyDown
        }
    }

    var allowClipping: Bool {
        switch self {
        case .fillScreen:
            return true
        case .fitScreen:
            return false
        }
    }
}
