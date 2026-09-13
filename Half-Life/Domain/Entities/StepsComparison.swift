//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepsComparison
//

import Foundation

/// The steps on days after a caffeine night, against the steps on other days: the Insights tab's steps screen.
///
/// A caffeine night is one with more than the sleep threshold in the body when the user fell asleep, the definition
/// every Insights comparison shares. ``StepsComparisonRule`` calculates the comparison. Its verdict names a difference
/// only when it's larger than the user's day-to-day swing explains, and never says caffeine caused it. Steps and
/// caffeine are health data, so no part of it is ever logged (constitution Article XI.6). See the Insights article.
struct StepsComparison: Sendable, Equatable {
    /// One day of the comparison.
    struct Day: Sendable, Equatable {
        /// The day's midnight.
        let day: Date
        /// The day's steps, or `nil` when Health has none for it.
        let steps: Int?
        /// Whether the night before it was a caffeine night.
        let followsCaffeineNight: Bool
    }

    /// The days of one side of the comparison that have steps.
    struct Group: Sendable, Equatable {
        /// The average of the days' steps.
        let averageSteps: Double
        /// How many days have steps.
        let dayCount: Int
    }

    /// What the comparison can honestly say.
    enum Verdict: Sendable, Equatable {
        /// A side has fewer than ``StepsComparisonRule/minimumDaysPerGroup`` days with steps.
        case tooFewDays
        /// The difference is within the day-to-day swing, so it could be chance.
        case noClearDifference
        /// Days after a caffeine night averaged this many fewer steps, beyond the day-to-day swing.
        case fewerAfterCaffeineNight(steps: Double)
        /// Days after a caffeine night averaged this many more steps, beyond the day-to-day swing.
        case moreAfterCaffeineNight(steps: Double)
    }

    /// Every day compared, oldest first, yesterday last, including the ones without steps.
    let days: [Day]
    /// The days after a caffeine night that have steps, or `nil` when there are none.
    let afterCaffeineNight: Group?
    /// The other days that have steps, or `nil` when there are none.
    let otherDays: Group?
    /// What the comparison can honestly say.
    let verdict: Verdict
    /// The sleep threshold the caffeine nights were judged against.
    let threshold: SleepThreshold
    /// Whether the steps came from the demo data sources rather than Apple Health.
    let isDemo: Bool
}
