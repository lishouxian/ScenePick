import AppKit

final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            InAppDailyWallpaperUpdater.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            InAppDailyWallpaperUpdater.shared.stop()
        }
    }
}
