import Foundation

public enum BingMarket: String, CaseIterable, Codable, Identifiable, Sendable {
    case china = "zh-CN"
    case unitedStates = "en-US"
    case japan = "ja-JP"
    case unitedKingdom = "en-GB"
    case germany = "de-DE"
    case france = "fr-FR"
    case canada = "en-CA"
    case australia = "en-AU"

    public var id: String { rawValue }
}
