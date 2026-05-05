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
        try expect(localizedString("resolution.preview", bundle: bundle) == "Preview (1366x768)", "English preview quality label")
        try expect(localizedString("preview.badge", bundle: bundle) == "Preview 1366x768", "English preview badge")
    }

    private static func simplifiedChineseLabelsUseChineseText(scenePickBundle: Bundle) throws {
        let bundle = try localizedBundle(in: scenePickBundle, languageCode: "zh-Hans")

        try expect(localizedString("market.china", bundle: bundle) == "中国", "Chinese China label")
        try expect(localizedString("market.unitedStates", bundle: bundle) == "美国", "Chinese United States label")
        try expect(localizedString("fillMode.fillScreen", bundle: bundle) == "填满屏幕", "Chinese fill screen label")
        try expect(localizedString("fillMode.fitScreen", bundle: bundle) == "适合屏幕", "Chinese fit screen label")
        try expect(localizedString("resolution.preview", bundle: bundle) == "预览 (1366x768)", "Chinese preview quality label")
        try expect(localizedString("preview.badge", bundle: bundle) == "预览 1366x768", "Chinese preview badge")
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
