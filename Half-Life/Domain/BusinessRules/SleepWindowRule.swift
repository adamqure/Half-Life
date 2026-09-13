//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepWindowRule
//

import Foundation

/// The business rule behind the Insights tab's "Best time to sleep tonight" card: when the caffeine already logged
/// falls to the sleep threshold tonight, and the 90 minutes to fall asleep in.
///
/// The night runs from 6pm to 4am in the user's calendar. From 6pm until 4am it's the night already running, and from
/// 4am until 6pm it's the coming one. The rule asks ``CaffeineDecayRule`` for the level at every whole minute from 6pm
/// to noon the next day, so the card and the curve always agree. Caffeine clears at the first whole minute after which
/// every level until noon is at or below the threshold, so a cup that rises over it in the evening moves the clearing
/// time after its fall. The window starts at the later of the clearing time and the bedtime. It holds no state and
/// reads no clock. ``CaffeineDecayRepository`` executes it. See the Insights article, SLEEPWIN-1 to SLEEPWIN-9.
struct SleepWindowRule: Sendable {
    /// What a window is calculated from, apart from the current time and the calendar.
    struct Inputs: Sendable, Equatable {
        /// Every intake that still counts.
        let intakes: [CaffeineIntake]
        /// The elimination half-life and the absorption rate.
        let kinetics: CaffeineKinetics
        /// The most caffeine the window allows in the body.
        let threshold: SleepThreshold
        /// The user's bedtime.
        let bedtime: Bedtime
    }

    /// The window's length: 90 minutes, about one sleep cycle.
    static let windowLength: TimeInterval = 90 * 60
    /// The hour the night starts, and the chart with it: 6pm.
    static let eveningHour = 18
    /// The hour the night ends, and the chart with it unless the window runs later: 4am.
    static let morningHour = 4
    /// The hour, the next day, after which the rule stops looking for caffeine to clear: noon.
    static let lastHour = 12
    private static let minute: TimeInterval = 60
    private let decay = CaffeineDecayRule()

    /// Returns the window for the night that's running at `now`, or the coming one.
    ///
    /// - Parameters:
    ///   - inputs: The intakes that still count, the kinetics, the threshold, and the bedtime.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, the night and the bedtime are in.
    /// - Returns: The window, or `nil` if the calendar can't find the night's hours or its bedtime.
    func window(_ inputs: Inputs, now: Date, calendar: Calendar) -> SleepWindow? {
        guard let shifted = calendar.date(byAdding: .hour, value: -Self.morningHour, to: now),
            let evening = calendar.date(bySettingHour: Self.eveningHour, minute: 0, second: 0, of: shifted),
            let nextDay = calendar.date(byAdding: .day, value: 1, to: evening),
            let morning = calendar.date(bySettingHour: Self.morningHour, minute: 0, second: 0, of: nextDay),
            let noon = calendar.date(bySettingHour: Self.lastHour, minute: 0, second: 0, of: nextDay),
            let bedtime = inputs.bedtime.next(atOrAfter: evening, in: calendar)
        else { return nil }
        // The levels run past noon by one window's length, so a window that starts just before noon is charted in full.
        let lastMinute = Int(noon.addingTimeInterval(Self.windowLength).timeIntervalSince(evening) / Self.minute)
        let levels = (0...lastMinute).map { minute in
            decay.level(
                at: evening.addingTimeInterval(Double(minute) * Self.minute), from: inputs.intakes,
                kinetics: inputs.kinetics)
        }
        let clearsAt = clearingTime(in: levels, through: noon, evening: evening, threshold: inputs.threshold)
        let window = clearsAt.map { DateInterval(start: max($0, bedtime), duration: Self.windowLength) }
        let chartEnd = window.map { max(morning, $0.end) } ?? noon
        return SleepWindow(
            evening: evening, bedtime: bedtime, clearsAt: clearsAt, window: window, chartEnd: chartEnd,
            threshold: inputs.threshold, levels: levels.filter { $0.date <= chartEnd })
    }

    /// The minute after the last one, up to `noon`, whose level is over `threshold`: `evening` if none is, or `nil` if
    /// the level at `noon` still is.
    private func clearingTime(
        in levels: [CaffeineLevel], through noon: Date, evening: Date, threshold: SleepThreshold
    ) -> Date? {
        let searched = levels.prefix { $0.date <= noon }
        guard let lastOver = searched.lastIndex(where: { $0.milligrams > threshold.milligrams }) else { return evening }
        guard lastOver < searched.index(before: searched.endIndex) else { return nil }
        return searched[lastOver + 1].date
    }
}
