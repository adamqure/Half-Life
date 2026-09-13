//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepNight
//

import Foundation

/// One night's sleep, summarized from the stage intervals Apple Health recorded.
///
/// ``SleepNightRule`` makes it, only for a night recorded with sleep stages. It holds when sleep started and ended,
/// and the two figures the half-life estimator scores a night by: deep sleep and time awake. See the Half-Life
/// Estimator article.
struct SleepNight: Sendable, Equatable {
    /// When the user first fell asleep: the start of the night's first stretch of sleep.
    let sleepOnset: Date
    /// When the user last woke: the end of the night's last stretch of sleep.
    let wake: Date
    /// The time in deep sleep, in seconds. Stretches that trackers recorded twice count once.
    let deepSeconds: TimeInterval
    /// The time awake between ``sleepOnset`` and ``wake``, in seconds. Stretches that trackers recorded twice count
    /// once.
    let awakeSeconds: TimeInterval
}
