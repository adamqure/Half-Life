//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogDay
//

import Foundation

/// One calendar day of the drink log: the drinks consumed that day, and their caffeine.
///
/// ``DrinkLogDayRule`` calculates it, and the Today screen's history card shows it. See the Today Screen article.
struct DrinkLogDay: Sendable, Equatable {
    /// The day's midnight, and the caffeine in every drink consumed that day, from ``DailyCaffeineIntakeRule``.
    let intake: DailyCaffeineIntake
    /// The drinks consumed that day, oldest first.
    let drinks: [LoggedDrink]
}
