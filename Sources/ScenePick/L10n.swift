import BingWallpapersCore
import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }
}

extension BingImage {
    var localizedDisplayTitle: String {
        displayTitle.isEmpty ? L10n.string("wallpaper.defaultTitle") : displayTitle
    }
}

extension BingMarket {
    var localizedLabel: String {
        switch self {
        case .china:
            return L10n.string("market.china")
        case .unitedStates:
            return L10n.string("market.unitedStates")
        case .japan:
            return L10n.string("market.japan")
        case .unitedKingdom:
            return L10n.string("market.unitedKingdom")
        case .germany:
            return L10n.string("market.germany")
        case .france:
            return L10n.string("market.france")
        case .canada:
            return L10n.string("market.canada")
        case .australia:
            return L10n.string("market.australia")
        }
    }
}

extension WallpaperResolution {
    var localizedLabel: String {
        switch self {
        case .uhd:
            return L10n.string("resolution.uhd")
        case .fullHD:
            return L10n.string("resolution.fullHD")
        case .preview:
            return L10n.string("resolution.preview")
        }
    }
}

extension WallpaperFillMode {
    var localizedLabel: String {
        switch self {
        case .fillScreen:
            return L10n.string("fillMode.fillScreen")
        case .fitScreen:
            return L10n.string("fillMode.fitScreen")
        }
    }
}
