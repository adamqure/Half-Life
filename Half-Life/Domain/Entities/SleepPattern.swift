//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepPattern
//

import Foundation

/// The finding on the Insights tab's first card: whether the user slept shorter or longer on the nights they fell
/// asleep with more than the sleep threshold in their body, over the Sleep screen's 30 days.
///
/// ``SleepPatternRule`` derives it from the Sleep screen's ``SleepCaffeineAnalysis``. It holds only counts and a
/// direction, never an amount of sleep. It's derived from caffeine and sleep, which are health data, so no part of it
/// is ever logged (constitution Article XI.6). See the Insights article.
struct SleepPattern: Sendable, Equatable {
    /// How the nights over the threshold compare with the others, by average time asleep.
    enum Direction: Sendable, Equatable {
        /// Shorter on the nights over the threshold, by 15 minutes or more.
        case shorter
        /// Longer on the nights over the threshold, by 15 minutes or more.
        case longer
        /// Less than 15 minutes apart, or too few nights to compare.
        case aboutTheSame
    }

    /// How much the finding can say, from the smaller group's nights.
    enum Confidence: Sendable, Equatable {
        /// Fewer than 5 nights, so the card is hidden.
        case tooFew
        /// 5 to 9 nights: "an early sign".
        case earlySign
        /// 10 nights or more: "consistent so far".
        case consistent
    }

    /// The period the nights ended in: from midnight on the first of its days to midnight after today.
    let period: DateInterval
    /// How many days the finding covers, today included.
    let days: Int
    /// The nights the user fell asleep with more than the threshold in their body.
    let nightsOver: Int
    /// The nights the user fell asleep with the threshold or less in their body.
    let nightsUnder: Int
    /// The threshold the nights were compared with: the user's tolerance, or the standard one without it.
    let threshold: SleepThreshold
    /// How the nights over the threshold compare with the others.
    let direction: Direction
    /// How much the finding can say.
    let confidence: Confidence

    /// The days without a counted night, because no sleep was recorded, or no drinks had been logged before it yet.
    var uncountedNights: Int {
        max(0, days - nightsOver - nightsUnder)
    }
}
