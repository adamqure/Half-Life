//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineNight
//

import Foundation

/// One past night, and the caffeine in the user when it began: at the sleep onset Apple Health recorded, or, for a
/// night Health recorded no sleep for, at the user's bedtime.
///
/// ``CaffeineNightRule`` calculates it with ``CaffeineDecayRule``, so it agrees with the curve. Every comparison on
/// the Insights tab reads the same nights, as the owner decided on 2026-09-13. See the Insights article.
struct CaffeineNight: Sendable, Equatable {
    /// Where a night's caffeine was measured.
    enum Moment: Sendable, Equatable {
        /// At the sleep onset Apple Health recorded.
        case sleepOnset
        /// At the user's bedtime, because Health recorded no sleep that night.
        case bedtime
    }

    /// Midnight at the start of the day the night follows.
    let day: Date
    /// When the caffeine was measured: the recorded sleep onset, or the bedtime.
    let moment: Date
    /// Whether ``moment`` is the recorded sleep onset or the bedtime.
    let measuredAt: Moment
    /// The caffeine in the body at ``moment``, in milligrams.
    let milligrams: Double
    /// Whether it's a caffeine night: its caffeine is over the history's threshold, strictly. ``CaffeineNightRule``
    /// decides it once, so every comparison on the tab splits the nights the same way.
    let isCaffeineNight: Bool
}

/// The caffeine of each of the last several nights, oldest first, with the sleep threshold it's judged against.
///
/// ``CaffeineNightRule`` makes it. See the Insights article.
struct CaffeineNightHistory: Sendable, Equatable {
    /// The nights, oldest first. The last is the night that followed yesterday.
    let nights: [CaffeineNight]
    /// The most caffeine the cutoff and the sleep window allow in the body at bedtime.
    let threshold: SleepThreshold
    /// Whether the sleep the onsets come from is the demo's, while Settings' demo Health data switch is on.
    let isDemo: Bool
}
