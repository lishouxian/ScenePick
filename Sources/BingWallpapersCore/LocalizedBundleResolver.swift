import Foundation

public enum LocalizedBundleResolver {
    public static func bundle(
        in resourceBundle: Bundle,
        languageCode: String
    ) -> Bundle? {
        if let path = resourceBundle.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        guard let resourceURL = resourceBundle.resourceURL else {
            return nil
        }

        let expectedDirectory = "\(languageCode).lproj".lowercased()
        let localizedDirectories = (try? FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil
        )) ?? []

        return localizedDirectories
            .first { $0.lastPathComponent.lowercased() == expectedDirectory }
            .flatMap { Bundle(url: $0) }
    }
}
