import AppKit

enum ApplicationVisibilityController {
    @MainActor
    static func apply(showDockIcon: Bool) {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }

    @MainActor
    static func activate() {
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    static func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        activate()
    }
}
