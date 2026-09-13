//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepHistory
//

import Foundation

/// The steps of each of several whole days before today, from Apple Health or the demo: what the Insights tab's steps
/// screen sets against caffeine.
///
/// Today is left out, because its steps are still growing. ``HealthDataRepository`` publishes it, and
/// ``StepsComparisonRule`` compares it. Steps are health data, so no part of it is ever logged (constitution Article
/// XI.6). See the Insights article.
struct StepHistory: Sendable, Equatable {
    /// One entry for each day, oldest first, yesterday last.
    let days: [DailySteps]
    /// Whether the steps came from the demo data sources rather than Apple Health.
    let isDemo: Bool
}

/// One day's steps.
struct DailySteps: Sendable, Equatable {
    /// The day's midnight, in the calendar the history was read in.
    let day: Date
    /// The day's steps, or `nil` when Health has none for it. It's `0` only when Health recorded zero.
    let steps: Int?
}
