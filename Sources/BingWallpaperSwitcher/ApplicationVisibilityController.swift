import AppKit

enum ApplicationVisibilityController {
    @MainActor
    static func apply(showDockIcon: Bool) {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }
}
