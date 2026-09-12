//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogRule
//

import Foundation

/// The business rule that decides whether a drink may be logged.
///
/// A drink needs a quantity of at least 1, and can't be consumed later than the current time. The rule holds no
/// state and reads no clock, so the current time is an input. ``DrinkLogRepository`` executes it for every drink it
/// logs, so every entry point gets the same checks. See the Drink Composer article.
struct DrinkLogRule: Sendable {
    /// Why a drink can't be logged.
    enum Violation: Error, Equatable {
        /// The quantity is below 1.
        case quantityBelowOne
        /// The drink was consumed later than the current time.
        case consumedInFuture
    }

    /// Checks that `drink` may be logged at `now`. The quantity is checked first.
    ///
    /// - Parameters:
    ///   - drink: The drink to check.
    ///   - now: The current time.
    /// - Throws: The ``Violation`` that stops the drink from being logged.
    func validate(_ drink: LoggedDrink, now: Date) throws {
        guard drink.quantity >= 1 else { throw Violation.quantityBelowOne }
        guard drink.consumedAt <= now else { throw Violation.consumedInFuture }
    }
}
