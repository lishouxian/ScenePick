import BingWallpapersCore
import Foundation

@MainActor
final class InAppDailyWallpaperUpdater {
    static let shared = InAppDailyWallpaperUpdater()

    private let defaults: UserDefaults
    private let calendar: Calendar
    private var observer: NSObjectProtocol?
    private var task: Task<Void, Never>?

    init(
        defaults: UserDefaults = BingWallpaperDefaults.store,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func start() {
        guard observer == nil else {
            refreshConfiguration()
            return
        }

        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshConfiguration()
            }
        }

        refreshConfiguration()
    }

    func stop() {
        task?.cancel()
        task = nil

        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    private func refreshConfiguration() {
        guard isEnabled else {
            task?.cancel()
            task = nil
            return
        }

        guard task == nil else {
            return
        }

        task = Task { [weak self] in
            await self?.runLoop()
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            let delay = delayUntilNextRun()
            if delay > 0 {
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    break
                }
            }

            guard isEnabled, !Task.isCancelled else {
                break
            }

            await setLatestWallpaper()
        }

        task = nil
    }

    private func setLatestWallpaper() async {
        do {
            let market = BingMarket(
                rawValue: defaults.string(forKey: BingWallpaperDefaultKeys.selectedMarket) ?? BingMarket.china.rawValue
            ) ?? .china
            let resolution = WallpaperResolution(
                rawValue: defaults.string(forKey: BingWallpaperDefaultKeys.selectedResolution) ?? WallpaperResolution.uhd.rawValue
            ) ?? .uhd
            let fillMode = WallpaperFillMode(
                rawValue: defaults.string(forKey: BingWallpaperDefaultKeys.fillMode) ?? WallpaperFillMode.fillScreen.rawValue
            ) ?? .fillScreen

            let images = try await BingWallpaperService().fetchArchive(market: market, count: 1)
            guard let latest = images.first else {
                throw BingWallpaperError.emptyArchive
            }

            let fileURL = try await WallpaperCache().cachedImageURL(
                for: latest,
                resolution: resolution
            )
            try MacDesktopWallpaperSetter().setDesktopImage(
                fileURL: fileURL,
                fillMode: fillMode
            )

            defaults.set(Date(), forKey: BingWallpaperDefaultKeys.lastDailyUpdateDate)
        } catch {
            NSLog("ScenePick daily update failed: \(error.localizedDescription)")
        }
    }

    private var isEnabled: Bool {
        BingWallpaperDefaults.bool(
            forKey: BingWallpaperDefaultKeys.dailyAutoUpdateEnabled,
            default: false
        )
    }

    private func delayUntilNextRun(now: Date = Date()) -> TimeInterval {
        if shouldRunNow(now: now) {
            return 2
        }

        return max(2, nextRunDate(after: now).timeIntervalSince(now))
    }

    private func shouldRunNow(now: Date) -> Bool {
        if let lastRun = defaults.object(forKey: BingWallpaperDefaultKeys.lastDailyUpdateDate) as? Date,
           calendar.isDate(lastRun, inSameDayAs: now) {
            return false
        }

        return now >= scheduledDate(on: now)
    }

    private func nextRunDate(after now: Date) -> Date {
        let today = scheduledDate(on: now)
        if now < today {
            return today
        }

        return calendar.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(24 * 60 * 60)
    }

    private func scheduledDate(on date: Date) -> Date {
        calendar.date(
            bySettingHour: 8,
            minute: 30,
            second: 0,
            of: date
        ) ?? date
    }
}
