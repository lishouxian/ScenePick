import Foundation

enum CoreL10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: localizedBundle, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    private static var localizedBundle: Bundle {
        guard let languageCode = BingWallpaperDefaults.store.string(forKey: BingWallpaperDefaultKeys.selectedLanguage),
              languageCode != "system",
              let path = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .module
        }

        return bundle
    }
}
