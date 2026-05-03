import Foundation

public enum BingWallpaperDefaultKeys {
    public static let selectedMarket = "selectedMarket"
    public static let selectedResolution = "selectedResolution"
    public static let fillMode = "fillMode"
    public static let autoSetLatestOnLaunch = "autoSetLatestOnLaunch"
    public static let dailyAutoUpdateEnabled = "dailyAutoUpdateEnabled"
    public static let showDockIcon = "showDockIcon"
    public static let showMenuBarIcon = "showMenuBarIcon"
}

public enum BingWallpaperDefaults {
    public static let suiteName = "com.xian.BingWallpaperSwitcher.settings"

    public static var store: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public static func bool(
        forKey key: String,
        default defaultValue: Bool
    ) -> Bool {
        let store = store
        guard store.object(forKey: key) != nil else {
            return defaultValue
        }

        return store.bool(forKey: key)
    }
}
