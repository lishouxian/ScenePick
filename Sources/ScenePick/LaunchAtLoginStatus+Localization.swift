import ScenePickSupport

extension LaunchAtLoginStatus {
    var localizedMessage: String {
        switch self {
        case .enabled:
            return L10n.string("launchAtLogin.status.enabled")
        case .disabled:
            return L10n.string("launchAtLogin.status.disabled")
        case .requiresApproval:
            return L10n.string("launchAtLogin.status.requiresApproval")
        case .unavailable:
            return L10n.string("launchAtLogin.status.unavailable")
        }
    }
}
