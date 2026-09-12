//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineStatus
//

import Foundation

/// The caffeine in the body right now, and what happens next: the decay card's figure and its two tips.
///
/// ``CaffeineStatusRule`` calculates it. See the Today Screen article.
nonisolated struct CaffeineStatus: Sendable, Equatable {
    /// The caffeine in the body at the current time.
    let level: CaffeineLevel
    /// The intakes still counting at the current time: the drinks still in your system, in the order given. A drink
    /// consumed at the current time counts, although none of its caffeine has reached the body yet.
    let activeIntakes: [CaffeineIntake]
    /// When the most recent of ``activeIntakes`` is down to half its dose, after its peak, or `nil` once that moment
    /// has passed or when nothing is counting.
    let lastIntakeHalfGoneAt: Date?
    /// The level at the next bedtime, or `nil` if the calendar can't find a next bedtime.
    let levelAtBedtime: CaffeineLevel?
}
