//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepHistory
//

import Foundation

/// The sleep that followed each of the last several days, from Apple Health or the demo: the Insights tab's last 7
/// days card.
///
/// ``SleepHistoryRule`` finds each night, and ``HealthDataRepository`` publishes the history. Sleep is health data, so
/// no part of it is ever logged (constitution Article XI.6). See the Insights article.
struct SleepHistory: Sendable, Equatable {
    /// One night for each day, oldest first, today last.
    let nights: [SleepHistoryNight]
    /// Whether the nights came from the demo data sources rather than Apple Health.
    let isDemo: Bool

    /// Whether any night has sleep or time in bed, so the card has sleep to show.
    var hasSleep: Bool {
        nights.contains { $0.sleep != nil }
    }
}

/// The night that followed one day: the one whose sleep ended from noon that day to noon the next.
struct SleepHistoryNight: Sendable, Equatable {
    /// The day's midnight, in the calendar the history was found in.
    let day: Date
    /// The night's sleep, its time in bed when no sleep was recorded, or `nil` when there's neither. Today's is always
    /// `nil`, because its night hasn't happened.
    let sleep: LastNightSleep?
}
