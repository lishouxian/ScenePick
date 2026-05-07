import Foundation

public struct DailyAutoUpdateSchedule: Sendable {
    public static let standard = DailyAutoUpdateSchedule()

    public let checkInterval: TimeInterval
    public let maximumRandomOffset: TimeInterval
    public let scheduledHour: Int
    public let scheduledMinute: Int
    public let calendar: Calendar

    public init(
        checkInterval: TimeInterval = 5 * 60,
        maximumRandomOffset: TimeInterval = 60,
        scheduledHour: Int = 8,
        scheduledMinute: Int = 30,
        calendar: Calendar = .current
    ) {
        self.checkInterval = checkInterval
        self.maximumRandomOffset = maximumRandomOffset
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.calendar = calendar
    }

    public func shouldRun(now: Date = Date(), lastRun: Date?) -> Bool {
        if let lastRun,
           calendar.isDate(lastRun, inSameDayAs: now) {
            return false
        }

        return now >= scheduledDate(on: now)
    }

    public func nextCheckDelay(randomOffset: TimeInterval) -> TimeInterval {
        checkInterval + min(max(0, randomOffset), maximumRandomOffset)
    }

    private func scheduledDate(on date: Date) -> Date {
        calendar.date(
            bySettingHour: scheduledHour,
            minute: scheduledMinute,
            second: 0,
            of: date
        ) ?? date
    }
}
