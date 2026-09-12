//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepStageInterval
//

import Foundation

/// A stretch of time that a sleep tracker recorded in one sleep stage.
///
/// It's what Apple Health records as one sleep analysis sample, without any HealthKit type. Trackers record
/// independently, so intervals from different trackers can overlap, and an in-bed interval can contain the asleep
/// and awake intervals recorded during it. Nothing here merges them. A business rule will turn a night's intervals
/// into a summary of that night's sleep. See the Sleep Data article.
struct SleepStageInterval: Sendable, Equatable {
    /// A sleep stage, as Apple Health records it.
    enum Stage: Sendable, Equatable {
        /// In bed, whether asleep or not.
        case inBed
        /// Awake during a sleep session.
        case awake
        /// Asleep, from a tracker that doesn't record stages.
        case asleepUnspecified
        /// Core, or light, sleep.
        case core
        /// Deep sleep.
        case deep
        /// REM sleep.
        case rem
    }

    /// The stage recorded.
    let stage: Stage
    /// When the stage started.
    let start: Date
    /// When the stage ended.
    let end: Date
}
