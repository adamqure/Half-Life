//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeDrinkLogRepository
//

import Foundation

@testable import Half_Life

/// An in-memory drink log repository for use case tests.
///
/// It streams the sets of drinks it was given, then finishes, and it records every drink logged to it. It's an
/// actor, like the live repositories.
actor FakeDrinkLogRepository: DrinkLogRepository {
    /// The sets of drinks that `loggedDrinks()` streams, in order.
    let drinks: [[LoggedDrink]]
    /// The error `log(_:)` throws instead of recording the drink, if any.
    let logError: (any Error)?
    /// Every drink logged so far, in order.
    private(set) var logged: [LoggedDrink] = []

    init(drinks: [[LoggedDrink]] = [], logError: (any Error)? = nil) {
        self.drinks = drinks
        self.logError = logError
    }

    nonisolated func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        AsyncStream { continuation in
            for set in drinks {
                continuation.yield(set)
            }
            continuation.finish()
        }
    }

    func log(_ drink: LoggedDrink) async throws {
        if let logError {
            throw logError
        }
        logged.append(drink)
    }
}
