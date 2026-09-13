//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffWarning
//

import Foundation

/// Why a drink the user is about to log breaks the caffeine cutoff: the drink composer's warning.
///
/// ``CaffeineCutoffRule/warning(_:consumedAt:calendar:)`` finds it. The warning never stops the drink being logged.
/// See the Caffeine Cutoff article.
nonisolated enum CutoffWarning: Sendable, Equatable {
    /// With the drink, more than the threshold would be in the body at bedtime.
    ///
    /// `level` is the caffeine at bedtime, with the drink and every intake logged, and its date is the bedtime.
    /// `threshold` is the most caffeine the cutoff allows then.
    case tooMuchAtBedtime(level: CaffeineLevel, threshold: SleepThreshold)
    /// The drink is consumed less than its peak delay before `bedtime`, so it would still be rising then.
    case stillRisingAtBedtime(bedtime: Date)
}
