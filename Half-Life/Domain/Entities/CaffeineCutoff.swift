//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineCutoff
//

import Foundation

/// The latest time the user's usual drink can be drunk and still leave no more than the sleep threshold in the body at
/// bedtime: the Today screen's "Last cup" tile.
///
/// ``CaffeineCutoffRule`` calculates it. See the Caffeine Cutoff article.
struct CaffeineCutoff: Sendable, Equatable {
    /// The drink the cutoff is for: the user's most logged drink and quantity.
    let drink: FavouriteDrink
    /// The half hour, :00 or :30 on the user's clock, by which the drink can be drunk, or `nil` when there's none:
    /// even a cup now would leave more than the threshold at bedtime, that half hour has passed, or bedtime is less
    /// than the drink's peak delay away.
    let latestCup: Date?
    /// The bedtime it's for: the first time the user's bedtime comes round at or after the current time.
    let bedtime: Date
    /// The most caffeine the cutoff allows in the body at bedtime.
    let threshold: SleepThreshold
}
