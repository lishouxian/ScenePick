import BingWallpapersCore
import Foundation

@main
struct ScenePickLocalizationSelfTest {
    static func main() throws {
        let scenePickBundle = try scenePickResourceBundle()

        try englishLabelsUseEnglishText(scenePickBundle: scenePickBundle)
        try simplifiedChineseLabelsUseChineseText(scenePickBundle: scenePickBundle)
        try languageLookupIsCaseInsensitive(scenePickBundle: scenePickBundle)

        print("ScenePickLocalizationSelfTest: 3 tests passed")
    }

    private static func englishLabelsUseEnglishText(scenePickBundle: Bundle) throws {
        let bundle = try localizedBundle(in: scenePickBundle, languageCode: "en")

        try expect(localizedString("market.china", bundle: bundle) == "China", "English China label")
        try expect(localizedString("market.unitedStates", bundle: bundle) == "United States", "English United States label")
        try expect(localizedString("fillMode.fillScreen", bundle: bundle) == "Fill Screen", "English fill screen label")
        try expect(localizedString("fillMode.fitScreen", bundle: bundle) == "Fit Screen", "English fit screen label")
        try expect(
            localizedString("dailyUpdate.help", bundle: bundle) == "Automatically switch to the latest wallpaper daily while ScenePick is running in the menu bar.",
            "English daily update help"
        )
        try expect(localizedString("launchAtLogin.title", bundle: bundle) == "Open at Login", "English launch at login title")
        try expect(localizedString("launchAtLogin.help", bundle: bundle) == "Recommended with daily auto-update.", "English launch at login help")
        try expect(
            localizedString("launchAtLogin.status.enabled", bundle: bundle) == "Enabled. ScenePick will open when you log in.",
            "English launch at login enabled status"
        )
        try expect(localizedString("launchAtLogin.status.disabled", bundle: bundle) == "Off.", "English launch at login disabled status")
        try expect(
            localizedString("launchAtLogin.status.requiresApproval", bundle: bundle) == "Needs approval in System Settings.",
            "English launch at login approval status"
        )
        try expect(
            localizedString("launchAtLogin.status.unavailable", bundle: bundle) == "Unavailable for this app build.",
            "English launch at login unavailable status"
        )
        try expect(
            localizedString("launchAtLogin.status.updating", bundle: bundle) == "Updating login item...",
            "English launch at login updating status"
        )
        try expect(
            localizedString("launchAtLogin.error", bundle: bundle) == "Could not update login item: %@",
            "English launch at login error"
        )
        try expect(localizedString("empty.title", bundle: bundle) == "Start with Bing daily wallpapers", "English empty title")
        try expect(localizedString("empty.subtitle", bundle: bundle) == "Reload wallpapers to browse the latest picks.", "English empty subtitle")
        try expect(localizedString("onboarding.menuBar.title", bundle: bundle) == "Menu bar access", "English menu bar onboarding title")
        try expect(
            localizedString("onboarding.menuBar.description", bundle: bundle) == "Use the menu bar icon to reopen ScenePick anytime.",
            "English menu bar onboarding description"
        )
        try expect(localizedString("onboarding.setDesktop.title", bundle: bundle) == "One-click desktop", "English set desktop onboarding title")
        try expect(
            localizedString("onboarding.setDesktop.description", bundle: bundle) == "Choose a wallpaper, then set it as your desktop from the main window or menu.",
            "English set desktop onboarding description"
        )
        try expect(localizedString("onboarding.dailyUpdate.title", bundle: bundle) == "Daily auto-update", "English daily update onboarding title")
        try expect(
            localizedString("onboarding.dailyUpdate.description", bundle: bundle) == "Enable daily auto-update to refresh your desktop while ScenePick stays open.",
            "English daily update onboarding description"
        )
        try expect(localizedString("resolution.preview", bundle: bundle) == "Preview (1366x768)", "English preview quality label")
        try expect(localizedString("preview.badge", bundle: bundle) == "Preview 1366x768", "English preview badge")
        try expect(localizedString("action.addFavorite", bundle: bundle) == "Add Favorite", "English add favorite action")
        try expect(localizedString("action.removeFavorite", bundle: bundle) == "Remove Favorite", "English remove favorite action")
        try expect(localizedString("sidebar.filter.label", bundle: bundle) == "Wallpaper List", "English wallpaper list filter label")
        try expect(localizedString("sidebar.filter.all", bundle: bundle) == "All", "English all filter")
        try expect(localizedString("sidebar.filter.favorites", bundle: bundle) == "Favorites", "English favorites filter")
        try expect(localizedString("sidebar.filter.recent", bundle: bundle) == "Recent", "English recent filter")
        try expect(localizedString("empty.favorites.title", bundle: bundle) == "No favorites yet", "English empty favorites title")
        try expect(
            localizedString("empty.favorites.subtitle", bundle: bundle) == "Use the star button to save wallpapers here.",
            "English empty favorites subtitle"
        )
        try expect(localizedString("empty.recent.title", bundle: bundle) == "No recent wallpapers yet", "English empty recent title")
        try expect(
            localizedString("empty.recent.subtitle", bundle: bundle) == "Set a wallpaper to see recent items.",
            "English empty recent subtitle"
        )
        try expect(localizedString("status.favoriteAdded", bundle: bundle) == "Added to favorites.", "English favorite added status")
        try expect(localizedString("status.favoriteRemoved", bundle: bundle) == "Removed from favorites.", "English favorite removed status")
        try expect(
            localizedString("error.favoriteLibraryUnsupportedVersion", bundle: bundle) == "Favorites data was created by a newer ScenePick version and was not changed.",
            "English favorite library unsupported version error"
        )
        try expect(
            localizedString("error.favoriteLibraryDamagedBackupCreated", bundle: bundle) == "Favorites data could not be read and was backed up.",
            "English damaged favorite library backup error"
        )
        try expect(
            localizedString("error.favoriteLibraryDamagedBackupFailed", bundle: bundle) == "Favorites data could not be read.",
            "English damaged favorite library backup failed error"
        )
    }

    private static func simplifiedChineseLabelsUseChineseText(scenePickBundle: Bundle) throws {
        let bundle = try localizedBundle(in: scenePickBundle, languageCode: "zh-Hans")

        try expect(localizedString("market.china", bundle: bundle) == "中国", "Chinese China label")
        try expect(localizedString("market.unitedStates", bundle: bundle) == "美国", "Chinese United States label")
        try expect(localizedString("fillMode.fillScreen", bundle: bundle) == "填满屏幕", "Chinese fill screen label")
        try expect(localizedString("fillMode.fitScreen", bundle: bundle) == "适合屏幕", "Chinese fit screen label")
        try expect(localizedString("dailyUpdate.help", bundle: bundle) == "拾景在菜单栏运行时，每天自动换成最新壁纸。", "Chinese daily update help")
        try expect(localizedString("launchAtLogin.title", bundle: bundle) == "开机启动", "Chinese launch at login title")
        try expect(localizedString("launchAtLogin.help", bundle: bundle) == "建议与每日自动换壁纸配合使用。", "Chinese launch at login help")
        try expect(
            localizedString("launchAtLogin.status.enabled", bundle: bundle) == "已开启。登录后会自动打开拾景。",
            "Chinese launch at login enabled status"
        )
        try expect(localizedString("launchAtLogin.status.disabled", bundle: bundle) == "已关闭。", "Chinese launch at login disabled status")
        try expect(
            localizedString("launchAtLogin.status.requiresApproval", bundle: bundle) == "需要在系统设置中批准。",
            "Chinese launch at login approval status"
        )
        try expect(
            localizedString("launchAtLogin.status.unavailable", bundle: bundle) == "当前应用构建不可用。",
            "Chinese launch at login unavailable status"
        )
        try expect(
            localizedString("launchAtLogin.status.updating", bundle: bundle) == "正在更新登录项...",
            "Chinese launch at login updating status"
        )
        try expect(localizedString("launchAtLogin.error", bundle: bundle) == "无法更新登录项：%@", "Chinese launch at login error")
        try expect(localizedString("empty.title", bundle: bundle) == "开始使用 Bing 每日壁纸", "Chinese empty title")
        try expect(localizedString("empty.subtitle", bundle: bundle) == "重新加载壁纸，浏览最新精选。", "Chinese empty subtitle")
        try expect(localizedString("onboarding.menuBar.title", bundle: bundle) == "菜单栏入口", "Chinese menu bar onboarding title")
        try expect(
            localizedString("onboarding.menuBar.description", bundle: bundle) == "随时通过菜单栏图标重新打开拾景。",
            "Chinese menu bar onboarding description"
        )
        try expect(localizedString("onboarding.setDesktop.title", bundle: bundle) == "一键设为桌面", "Chinese set desktop onboarding title")
        try expect(
            localizedString("onboarding.setDesktop.description", bundle: bundle) == "选择壁纸后，可在主窗口或菜单中设为桌面。",
            "Chinese set desktop onboarding description"
        )
        try expect(localizedString("onboarding.dailyUpdate.title", bundle: bundle) == "每日自动换壁纸", "Chinese daily update onboarding title")
        try expect(
            localizedString("onboarding.dailyUpdate.description", bundle: bundle) == "开启每日自动换壁纸后，应用保持运行时会自动更新桌面。",
            "Chinese daily update onboarding description"
        )
        try expect(localizedString("resolution.preview", bundle: bundle) == "预览 (1366x768)", "Chinese preview quality label")
        try expect(localizedString("preview.badge", bundle: bundle) == "预览 1366x768", "Chinese preview badge")
        try expect(localizedString("action.addFavorite", bundle: bundle) == "加入收藏", "Chinese add favorite action")
        try expect(localizedString("action.removeFavorite", bundle: bundle) == "取消收藏", "Chinese remove favorite action")
        try expect(localizedString("sidebar.filter.label", bundle: bundle) == "壁纸列表", "Chinese wallpaper list filter label")
        try expect(localizedString("sidebar.filter.all", bundle: bundle) == "全部", "Chinese all filter")
        try expect(localizedString("sidebar.filter.favorites", bundle: bundle) == "收藏", "Chinese favorites filter")
        try expect(localizedString("sidebar.filter.recent", bundle: bundle) == "最近", "Chinese recent filter")
        try expect(localizedString("empty.favorites.title", bundle: bundle) == "还没有收藏", "Chinese empty favorites title")
        try expect(
            localizedString("empty.favorites.subtitle", bundle: bundle) == "使用星标按钮，把喜欢的壁纸保存在这里。",
            "Chinese empty favorites subtitle"
        )
        try expect(localizedString("empty.recent.title", bundle: bundle) == "还没有设置过壁纸", "Chinese empty recent title")
        try expect(
            localizedString("empty.recent.subtitle", bundle: bundle) == "设为桌面后，会在这里看到最近项目。",
            "Chinese empty recent subtitle"
        )
        try expect(localizedString("status.favoriteAdded", bundle: bundle) == "已加入收藏。", "Chinese favorite added status")
        try expect(localizedString("status.favoriteRemoved", bundle: bundle) == "已取消收藏。", "Chinese favorite removed status")
        try expect(
            localizedString("error.favoriteLibraryUnsupportedVersion", bundle: bundle) == "收藏数据由更新版本的拾景创建，本次未做修改。",
            "Chinese favorite library unsupported version error"
        )
        try expect(
            localizedString("error.favoriteLibraryDamagedBackupCreated", bundle: bundle) == "收藏数据无法读取，已隔离备份。",
            "Chinese damaged favorite library backup error"
        )
        try expect(
            localizedString("error.favoriteLibraryDamagedBackupFailed", bundle: bundle) == "收藏数据无法读取。",
            "Chinese damaged favorite library backup failed error"
        )
    }

    private static func languageLookupIsCaseInsensitive(scenePickBundle: Bundle) throws {
        let exactPath = scenePickBundle.path(forResource: "zh-Hans", ofType: "lproj")
        try expect(exactPath == nil, "SwiftPM currently lowercases zh-Hans resource directories")

        let bundle = try localizedBundle(in: scenePickBundle, languageCode: "zh-Hans")
        try expect(localizedString("market.china", bundle: bundle) == "中国", "case-insensitive zh-Hans lookup")
    }

    private static func localizedString(_ key: String, bundle: Bundle) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    private static func localizedBundle(
        in resourceBundle: Bundle,
        languageCode: String
    ) throws -> Bundle {
        try require(
            LocalizedBundleResolver.bundle(in: resourceBundle, languageCode: languageCode),
            "localized bundle for \(languageCode)"
        )
    }

    private static func scenePickResourceBundle() throws -> Bundle {
        let binDirectory = try require(
            ProcessInfo.processInfo.environment["SCENEPICK_BIN_DIR"],
            "SCENEPICK_BIN_DIR"
        )
        let bundleURL = URL(fileURLWithPath: binDirectory)
            .appendingPathComponent("ScenePick_ScenePick.bundle", isDirectory: true)

        return try require(Bundle(url: bundleURL), "ScenePick_ScenePick.bundle")
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        guard condition else {
            throw SelfTestError.expectationFailed(message)
        }
    }

    private static func require<Value>(_ value: Value?, _ message: String) throws -> Value {
        guard let value else {
            throw SelfTestError.expectationFailed(message)
        }

        return value
    }
}

private enum SelfTestError: LocalizedError {
    case expectationFailed(String)

    var errorDescription: String? {
        switch self {
        case .expectationFailed(let message):
            return message
        }
    }
}
