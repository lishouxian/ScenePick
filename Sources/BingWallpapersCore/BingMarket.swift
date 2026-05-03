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

    public var label: String {
        switch self {
        case .china:
            return "China"
        case .unitedStates:
            return "United States"
        case .japan:
            return "Japan"
        case .unitedKingdom:
            return "United Kingdom"
        case .germany:
            return "Germany"
        case .france:
            return "France"
        case .canada:
            return "Canada"
        case .australia:
            return "Australia"
        }
    }
}
