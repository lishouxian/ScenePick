import AppKit
import Foundation

public protocol DesktopWallpaperSetting {
    func setDesktopImage(fileURL: URL, fillMode: WallpaperFillMode) throws
}

public protocol DesktopScreenTarget {
    var identityToken: AnyHashable { get }
}

public protocol DesktopScreenEnumerating {
    func availableScreens() -> [any DesktopScreenTarget]
}

public protocol PerScreenWallpaperSetting {
    func setDesktopImage(
        fileURL: URL,
        on screen: any DesktopScreenTarget,
        options: [NSWorkspace.DesktopImageOptionKey: Any]
    ) throws
}

public final class MacDesktopWallpaperSetter: DesktopWallpaperSetting {
    private let fileManager: FileManager
    private let screenEnumerator: any DesktopScreenEnumerating
    private let perScreenSetter: any PerScreenWallpaperSetting

    public init(
        fileManager: FileManager = .default,
        screenEnumerator: any DesktopScreenEnumerating = SystemDesktopScreenEnumerator(),
        perScreenSetter: any PerScreenWallpaperSetting = SystemPerScreenWallpaperSetter()
    ) {
        self.fileManager = fileManager
        self.screenEnumerator = screenEnumerator
        self.perScreenSetter = perScreenSetter
    }

    public func setDesktopImage(
        fileURL: URL,
        fillMode: WallpaperFillMode = .fillScreen
    ) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw BingWallpaperError.missingCachedFile(fileURL)
        }

        let screens = screenEnumerator.availableScreens()
        guard !screens.isEmpty else {
            throw BingWallpaperError.noScreensAvailable
        }

        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: fillMode.imageScaling.rawValue,
            .allowClipping: fillMode.allowClipping
        ]

        var failureCount = 0
        for screen in screens {
            do {
                try perScreenSetter.setDesktopImage(
                    fileURL: fileURL,
                    on: screen,
                    options: options
                )
            } catch {
                failureCount += 1
            }
        }

        if failureCount > 0 {
            throw BingWallpaperError.someScreensFailed(
                succeeded: screens.count - failureCount,
                total: screens.count
            )
        }
    }
}

public struct SystemDesktopScreenEnumerator: DesktopScreenEnumerating {
    public init() {}

    public func availableScreens() -> [any DesktopScreenTarget] {
        NSScreen.screens.map(SystemDesktopScreenTarget.init(screen:))
    }
}

public struct SystemPerScreenWallpaperSetter: PerScreenWallpaperSetting {
    public init() {}

    public func setDesktopImage(
        fileURL: URL,
        on screen: any DesktopScreenTarget,
        options: [NSWorkspace.DesktopImageOptionKey: Any]
    ) throws {
        guard let screen = screen as? SystemDesktopScreenTarget else {
            throw SystemDesktopScreenError.invalidScreenTarget
        }

        try NSWorkspace.shared.setDesktopImageURL(
            fileURL,
            for: screen.screen,
            options: options
        )
    }
}

private struct SystemDesktopScreenTarget: DesktopScreenTarget {
    let screen: NSScreen

    var identityToken: AnyHashable {
        AnyHashable(ObjectIdentifier(screen))
    }
}

private enum SystemDesktopScreenError: Error {
    case invalidScreenTarget
}

public enum WallpaperFillMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case fillScreen
    case fitScreen

    public var id: String { rawValue }

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
