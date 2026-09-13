//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RestingHeartRateHistory
//

import Foundation

/// One day's resting heart rate, from Apple Health or the demo.
struct RestingHeartRateDay: Sendable, Equatable {
    /// Midnight at the start of the day.
    let day: Date
    /// The average of the day's resting heart rates, in beats per minute, or `nil` if there's none. HealthKit doesn't
    /// reveal a denial, so a day the user didn't allow looks like a day with none.
    let beatsPerMinute: Double?
}

/// The resting heart rate of each of the last several days, oldest first, today last.
///
/// ``HealthDataRepository`` publishes it. See the Insights article.
struct RestingHeartRateHistory: Sendable, Equatable {
    /// The days, oldest first, today last.
    let days: [RestingHeartRateDay]
    /// Whether the readings are the demo's, while Settings' demo Health data switch is on.
    let isDemo: Bool
}
