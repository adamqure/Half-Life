//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LogDrinkUseCase
//

import Foundation

/// Records a drink the user consumed.
///
/// The composer, one-tap favourites, and App Intents all log drinks through this use case. It reads the current
/// time, builds the drink, and logs it through ``DrinkLogRepository``, which checks it with ``DrinkLogRule``. The
/// decay curve hears about the drink from the data source the two repositories share, not from this use case.
struct LogDrinkUseCase: UseCase {
    /// The drink to record.
    struct Input: Sendable, Equatable {
        /// Which drink.
        let type: DrinkType
        /// How many units of the drink's ``DrinkType/unit``.
        let quantity: Int
        /// How long before now the drink was consumed, in seconds. 0 is now.
        let secondsAgo: TimeInterval
    }

    /// The repository that supplies the current time.
    let currentTime: any CurrentTimeRepository
    /// The repository that stores the drink.
    let drinkLog: any DrinkLogRepository

    /// Logs the drink consumed `input.secondsAgo` seconds before now, with its estimated caffeine.
    ///
    /// - Parameter input: The drink to record.
    /// - Throws: The repository's error if the drink can't be logged or stored.
    func execute(_ input: Input) async throws {
        let drink = LoggedDrink(
            type: input.type,
            quantity: input.quantity,
            milligrams: input.type.estimatedMilligrams(quantity: input.quantity),
            consumedAt: currentTime.now().addingTimeInterval(-input.secondsAgo))
        try await drinkLog.log(drink)
    }
}
