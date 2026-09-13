//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepHistoryRule
//

import Foundation

/// The business rule behind the sleep on the Insights tab's last 7 days card: the night that followed each day.
///
/// A day's night is the one ``LastNightSleepRule`` finds for the next day: the latest night whose last sleep ends from
/// noon that day to noon the next. So the card and the Today screen's Apple Health card always agree on a night,
/// including its time in bed when no sleep was recorded. Today's night hasn't happened, so it's always empty. The
/// repository reads sleep once, for ``range(endingAt:days:calendar:)``, and the rule finds every night in that one
/// read. It holds no state and reads no clock. ``HealthDataRepository`` executes it. See the Insights article,
/// SLEEPHIST-1 to SLEEPHIST-4.
struct SleepHistoryRule {
    /// How far before the first night's window sleep is read, so a night that started the day before is read whole.
    private static let lookBack: TimeInterval = 24 * 3_600
    private let lastNightRule = LastNightSleepRule()

    /// Returns the time to read sleep for: from a day before noon on the first day, to noon today, where last night's
    /// window ends. The Today screen's Apple Health card reads to the same noon, so a night that hasn't finished gives
    /// both cards the same answer.
    ///
    /// - Parameters:
    ///   - now: The current time, on the last day.
    ///   - days: How many days, today included.
    ///   - calendar: The calendar, and so the time zone, whose days and noons define the nights.
    /// - Returns: The range, or `nil` if there are no days or the calendar can't find the first day's or today's noon.
    func range(endingAt now: Date, days: Int, calendar: Calendar) -> DateInterval? {
        guard days > 0, let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: now),
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: firstDay),
            let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)
        else { return nil }
        let start = noon.addingTimeInterval(-Self.lookBack)
        return DateInterval(start: start, end: max(start, noonToday))
    }

    /// Returns the night that followed each of the last `days` days, oldest first, today last.
    ///
    /// - Parameters:
    ///   - intervals: The sleep Health recorded, from any trackers, in any order.
    ///   - now: The current time, on the last day.
    ///   - days: How many days, today included.
    ///   - calendar: The calendar, and so the time zone, whose days and noons define the nights.
    func nights(
        from intervals: [SleepStageInterval], endingAt now: Date, days: Int, calendar: Calendar
    ) -> [SleepHistoryNight] {
        (0..<max(days, 0)).reversed().compactMap { daysAgo in
            guard let moment = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return nil }
            let day = calendar.startOfDay(for: moment)
            guard daysAgo > 0,
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day),
                let noonNextDay = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: nextDay)
            else { return SleepHistoryNight(day: day, sleep: nil) }
            return SleepHistoryNight(
                day: day, sleep: lastNightRule.lastNight(from: intervals, at: noonNextDay, calendar: calendar))
        }
    }
}
