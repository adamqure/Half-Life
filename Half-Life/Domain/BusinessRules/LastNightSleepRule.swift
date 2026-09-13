//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LastNightSleepRule
//

import Foundation

/// Finds last night in the sleep intervals Apple Health recorded, for the Apple Health card.
///
/// It groups intervals into sessions exactly as ``SleepNightRule`` does, and a session needs the same 3 hours of sleep
/// to be a night rather than a nap. Last night is the latest such session whose last sleep ends from noon yesterday,
/// included, to noon today, excluded, in the given calendar. Its time asleep is the union of its sleep, with
/// overlapping trackers counted once.
///
/// Unlike ``SleepNightRule``, it counts sleep recorded without stages, because the card only reports what Health
/// recorded. With no sleep in the window, the time in bed ending in it, grouped the same way and at least 3 hours
/// long, is the fallback. It holds no state and reads no clock. ``HealthDataRepository`` executes it. The Apple Health
/// Card article lists its requirements, LASTNIGHT-1 to LASTNIGHT-7.
struct LastNightSleepRule {
    /// Returns the window last night's sleep must end in: from noon on the day before the one `now` falls in, to noon
    /// on that day.
    ///
    /// - Parameters:
    ///   - now: Any moment on the day whose last night to find.
    ///   - calendar: The calendar, and so the time zone, whose noons bound the window.
    /// - Returns: The window, or `nil` if the calendar has no noon on that day.
    func night(containing now: Date, calendar: Calendar) -> DateInterval? {
        guard let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now),
            let noonYesterday = calendar.date(byAdding: .day, value: -1, to: noonToday)
        else { return nil }
        return DateInterval(start: noonYesterday, end: noonToday)
    }

    /// Returns last night's sleep, or its time in bed when no sleep was recorded.
    ///
    /// - Parameters:
    ///   - intervals: The intervals Health recorded, from any trackers, in any order.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, whose noons bound last night.
    /// - Returns: The time asleep in the latest night ending in the window, the time in bed if there's no such night,
    ///   or `nil` if there's neither.
    func lastNight(from intervals: [SleepStageInterval], at now: Date, calendar: Calendar) -> LastNightSleep? {
        guard let window = night(containing: now, calendar: calendar) else { return nil }
        let sessions = SleepNightRule.sessions(of: intervals.filter { $0.stage.isAsleep || $0.stage == .awake })
        if let asleep = Self.latestLength(of: sessions.map { $0.filter(\.stage.isAsleep) }, endingIn: window) {
            return .asleep(seconds: asleep)
        }
        let inBed = SleepNightRule.sessions(of: intervals.filter { $0.stage == .inBed })
        return Self.latestLength(of: inBed, endingIn: window).map { .inBedOnly(seconds: $0) }
    }

    /// The time covered by the latest of `groups` that ends in `window` and covers at least 3 hours, with overlaps
    /// counted once, or `nil` if none does.
    private static func latestLength(
        of groups: [[SleepStageInterval]], endingIn window: DateInterval
    ) -> TimeInterval? {
        groups.compactMap { group -> (end: Date, length: TimeInterval)? in
            guard let start = group.map(\.start).min(), let end = group.map(\.end).max(),
                end >= window.start, end < window.end
            else { return nil }
            let length = SleepNightRule.unionLength(of: group, within: DateInterval(start: start, end: end))
            return length >= SleepNightRule.minimumAsleepSeconds ? (end, length) : nil
        }
        .max { $0.end < $1.end }?.length
    }
}
