//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepCaffeineAnalysis
//

import Foundation

/// The Insights tab's Sleep screen: each night's sleep in the last 30 days against the caffeine in the user at sleep
/// onset.
///
/// ``SleepToleranceRule`` makes it, and ``SleepToleranceRepository`` publishes it. It's health data, so no part of it
/// is ever logged (constitution Article XI.6). See the Insights article.
struct SleepCaffeineAnalysis: Sendable, Equatable {
    /// The nights, in order of sleep onset.
    let nights: [SleepCaffeineNight]
    /// The user's tolerance, or `nil` when the nights can't show one yet.
    let tolerance: SleepTolerance?
    /// Time asleep on the nights at or under the threshold in use, against the nights over it, or `nil` with fewer
    /// than 5 nights on either side.
    let timeAsleep: SleepComparison?
    /// The time to fall asleep on the nights at or under the threshold in use, against the nights over it, among the
    /// nights with time in bed recorded, or `nil` with fewer than 5 such nights on either side.
    let timeToFallAsleep: SleepComparison?
    /// The period the nights ended in: from midnight on the first of its days to midnight after today.
    let period: DateInterval
    /// How many days the period covers, today included: 30.
    let days: Int
    /// Whether the sleep came from the demo data sources rather than Apple Health.
    let isDemo: Bool

    /// The threshold the app uses: the tolerance, or ``SleepThreshold/standard`` without one.
    var threshold: SleepThreshold {
        tolerance.flatMap { SleepThreshold(milligrams: $0.milligrams) } ?? .standard
    }
}

/// One night's sleep, and the caffeine in the user when it began.
struct SleepCaffeineNight: Sendable, Equatable {
    /// When the user first fell asleep: the start of the night's first stretch of sleep.
    let sleepOnset: Date
    /// The time asleep, in seconds, with stretches that trackers recorded twice counted once.
    let asleepSeconds: TimeInterval
    /// How long the user took to fall asleep, from getting into bed, in seconds, or `nil` when Health recorded no time
    /// in bed around the onset.
    let secondsToFallAsleep: TimeInterval?
    /// The caffeine in the body at ``sleepOnset``, in milligrams, from ``CaffeineDecayRule``.
    let caffeineAtOnset: Double
}

/// A sleep measure on the nights at or under a threshold, against the nights over it.
struct SleepComparison: Sendable, Equatable {
    /// The average on the nights at or under the threshold, in seconds.
    let underSeconds: TimeInterval
    /// The average on the nights over the threshold, in seconds.
    let overSeconds: TimeInterval
    /// How many nights were at or under the threshold.
    let nightsUnder: Int
    /// How many nights were over the threshold.
    let nightsOver: Int
}
