import Foundation

enum CoreL10n {
    private static let resourceBundle = Bundle.scenePickResourceBundle(named: "ScenePick_BingWallpapersCore")

    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: localizedBundle, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    private static var localizedBundle: Bundle {
        guard let languageCode = BingWallpaperDefaults.store.string(forKey: BingWallpaperDefaultKeys.selectedLanguage),
              languageCode != "system",
              let path = resourceBundle.path(forResource: languageCode, ofType: "lproj"),
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
