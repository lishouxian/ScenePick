import BingWallpapersCore
import Foundation

enum L10n {
    private static let resourceBundle = Bundle.scenePickResourceBundle(named: "ScenePick_ScenePick")

    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: localizedBundle, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    private static var localizedBundle: Bundle {
        let language = AppLanguage(
            rawValue: BingWallpaperDefaults.store.string(forKey: BingWallpaperDefaultKeys.selectedLanguage) ?? ""
        ) ?? .system

        guard language != .system,
              let path = resourceBundle.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return resourceBundle
        }

        return bundle
    }
}

private extension Bundle {
    static func scenePickResourceBundle(named name: String) -> Bundle {
        let bundleName = "\(name).bundle"
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent(bundleName),
            Bundle.main.bundleURL.appendingPathComponent(bundleName)
        ]

        for candidate in candidates {
            if let candidate, let bundle = Bundle(url: candidate) {
                return bundle
            }
        }

        return .main
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .system:
            return L10n.string("language.system")
        case .english:
            return L10n.string("language.english")
        case .simplifiedChinese:
            return L10n.string("language.simplifiedChinese")
        }
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
