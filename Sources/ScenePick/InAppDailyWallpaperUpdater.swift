import BingWallpapersCore
import Foundation

@MainActor
final class InAppDailyWallpaperUpdater {
    static let shared = InAppDailyWallpaperUpdater()

    private let defaults: UserDefaults
    private let schedule: DailyAutoUpdateSchedule
    private var observer: NSObjectProtocol?
    private var task: Task<Void, Never>?

    init(
        defaults: UserDefaults = BingWallpaperDefaults.store,
        schedule: DailyAutoUpdateSchedule = .standard
    ) {
        self.defaults = defaults
        self.schedule = schedule
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
            if schedule.shouldRun(lastRun: lastRunDate) {
                await setLatestWallpaper()
            }

            guard isEnabled, !Task.isCancelled else {
                break
            }

            do {
                try await Task.sleep(nanoseconds: nextCheckDelayNanoseconds())
            } catch {
                break
            }
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

    private var lastRunDate: Date? {
        defaults.object(forKey: BingWallpaperDefaultKeys.lastDailyUpdateDate) as? Date
    }

    private func nextCheckDelayNanoseconds() -> UInt64 {
        let randomOffset = TimeInterval.random(in: 0...schedule.maximumRandomOffset)
        let delay = schedule.nextCheckDelay(randomOffset: randomOffset)
        return UInt64(delay * 1_000_000_000)
    }
}
