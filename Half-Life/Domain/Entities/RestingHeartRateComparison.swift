//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RestingHeartRateComparison
//

import Foundation

/// The user's resting heart rate on the days after a night that began with caffeine over the sleep threshold, set
/// against the other days.
///
/// ``RestingHeartRateComparisonRule`` calculates it, and the Insights tab's resting heart rate screen shows it. It
/// states what the user's own days show, never a cause. See the Insights article.
struct RestingHeartRateComparison: Sendable, Equatable {
    /// One day with a resting heart rate, and whether the night before it began with caffeine over the threshold.
    struct Day: Sendable, Equatable {
        /// Midnight at the start of the day.
        let day: Date
        /// The day's resting heart rate, in beats per minute.
        let beatsPerMinute: Double
        /// Whether the night before the day began with caffeine over the threshold.
        let followsCaffeine: Bool
        /// Whether the night before was measured at its recorded sleep onset, or at the bedtime.
        let measuredAt: CaffeineNight.Moment
    }

    /// One side of the comparison: the days after a caffeine night, or the other days.
    struct Group: Sendable, Equatable {
        /// How many days the group has.
        let dayCount: Int
        /// The group's average resting heart rate, in beats per minute, or `nil` when it has no days.
        let averageBeatsPerMinute: Double?
    }

    /// What the days show, from ``RestingHeartRateComparisonRule``.
    enum Finding: Sendable, Equatable {
        /// A group has fewer than ``RestingHeartRateComparisonRule/minimumDays`` days, so nothing is claimed yet.
        case notEnoughDays
        /// The difference is within the user's own day-to-day variation, or under a beat per minute.
        case noClearDifference
        /// The difference is more than twice its standard error, and at least a beat per minute.
        case pattern
    }

    /// The days with a resting heart rate and a night before them, oldest first.
    let days: [Day]
    /// The threshold the nights were judged against.
    let threshold: SleepThreshold
    /// The days after a night that began with caffeine over the threshold.
    let afterCaffeine: Group
    /// The days after a night that began with caffeine at or under it.
    let otherDays: Group
    /// What the days show.
    let finding: Finding
    /// Whether the resting heart rates are the demo's.
    let isDemo: Bool

    /// How much higher the average is after a caffeine night than on the other days, in beats per minute, negative
    /// when it's lower, or `nil` when either group has no days.
    var difference: Double? {
        guard let after = afterCaffeine.averageBeatsPerMinute,
            let other = otherDays.averageBeatsPerMinute
        else {
            return nil
        }
        return after - other
    }
}
