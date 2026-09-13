//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineNightRule
//

import Foundation

/// The business rule behind every comparison on the Insights tab: the caffeine in the user when each past night began.
///
/// The owner decided on 2026-09-13 that the tab has one definition of a caffeine night, so its comparisons never
/// disagree:
///
/// - **A night with a recorded sleep onset** is measured there. A day's night is the first onset from noon that day to
///   noon the next, so an onset after midnight belongs to the day before it. The onsets are the nights the caller
///   recognises in Apple Health's sleep, so the Sleep screen's night definition stays the only one.
/// - **A night with none** is measured at the user's bedtime: the first time it comes round at or after 6pm that day,
///   as for ``SleepWindowRule``. It's marked, so a comparison of sleep that happened can leave it out.
///
/// The caffeine is ``CaffeineDecayRule``'s level at that moment, from every intake, including the ones that no longer
/// count now, because they counted then. A night is a caffeine night when it's over the threshold, strictly, decided
/// here once for every comparison. It holds no state and reads no clock. See the Insights article, CNIGHT-1 to
/// CNIGHT-7.
struct CaffeineNightRule: Sendable {
    /// What the nights are calculated from, apart from the current time and the calendar.
    struct Inputs: Sendable, Equatable {
        /// The sleep onsets Apple Health recorded, in any order.
        let onsets: [Date]
        /// Every intake the user logged.
        let intakes: [CaffeineIntake]
        /// The elimination half-life and the absorption rate.
        let kinetics: CaffeineKinetics
        /// The user's bedtime, for the nights with no recorded onset.
        let bedtime: Bedtime
        /// The threshold the nights are judged against.
        let threshold: SleepThreshold
        /// Whether the onsets come from the demo's sleep.
        let isDemo: Bool
    }

    /// The hour a day's night starts looking for a recorded onset, and ends the day before's: noon.
    static let nightStartHour = 12
    private let decay = CaffeineDecayRule()

    /// Returns the caffeine at the start of each of the nights that followed the `days` days before the one `now`
    /// falls in.
    ///
    /// - Parameters:
    ///   - inputs: The recorded onsets, the intakes, the kinetics, the bedtime, the threshold, and whether it's the
    ///     demo.
    ///   - days: How many nights, the one that followed yesterday last.
    ///   - now: The current time, which fixes which day is today.
    ///   - calendar: The calendar, and so the time zone, the days, the noons, and the bedtime are in.
    /// - Returns: The nights, oldest first. A night the calendar can't find the hours of is left out.
    func history(_ inputs: Inputs, days: Int, now: Date, calendar: Calendar) -> CaffeineNightHistory {
        let today = calendar.startOfDay(for: now)
        let onsets = inputs.onsets.sorted()
        let nights = stride(from: days, to: 0, by: -1).compactMap { daysAgo -> CaffeineNight? in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today),
                let found = moment(of: day, onsets: onsets, bedtime: inputs.bedtime, calendar: calendar)
            else { return nil }
            let level = decay.level(at: found.date, from: inputs.intakes, kinetics: inputs.kinetics)
            return CaffeineNight(
                day: day, moment: found.date, measuredAt: found.measuredAt, milligrams: level.milligrams,
                isCaffeineNight: level.milligrams > inputs.threshold.milligrams)
        }
        return CaffeineNightHistory(nights: nights, threshold: inputs.threshold, isDemo: inputs.isDemo)
    }

    /// The moment the night after `day` is measured at: its first recorded onset from noon that day to noon the next,
    /// or else its bedtime.
    private func moment(
        of day: Date, onsets: [Date], bedtime: Bedtime, calendar: Calendar
    ) -> (date: Date, measuredAt: CaffeineNight.Moment)? {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day),
            let start = calendar.date(bySettingHour: Self.nightStartHour, minute: 0, second: 0, of: day),
            let end = calendar.date(bySettingHour: Self.nightStartHour, minute: 0, second: 0, of: nextDay)
        else { return nil }
        if let onset = onsets.first(where: { $0 >= start && $0 < end }) {
            return (onset, .sleepOnset)
        }
        guard
            let evening = calendar.date(
                bySettingHour: SleepWindowRule.eveningHour, minute: 0, second: 0, of: day),
            let bedtime = bedtime.next(atOrAfter: evening, in: calendar)
        else { return nil }
        return (bedtime, .bedtime)
    }
}
