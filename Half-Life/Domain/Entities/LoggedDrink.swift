//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LoggedDrink
//

import Foundation

/// One drink the user consumed.
///
/// A logged drink keeps the caffeine it was logged with. If a later version corrects a drink's caffeine per unit,
/// drinks already logged keep their amounts, so history and past curves don't change. A drink is the user's own unless
/// it's marked as a demo drink, one of the sample history that Settings adds. See the Drink Composer and Settings
/// articles.
struct LoggedDrink: Identifiable, Equatable, Sendable {
    /// Identifies the drink, so it can be listed, and later deleted or edited. Its intake shares it.
    let id: UUID
    /// Which drink.
    let type: DrinkType
    /// How many units of the drink's ``DrinkType/unit``.
    let quantity: Int
    /// The total estimated caffeine, in milligrams. Stored when the drink is logged, never recalculated.
    let milligrams: Double
    /// When the drink was consumed. It can be earlier than when it was logged.
    let consumedAt: Date
    /// Whether the drink is part of the demo history rather than one the user logged. The history card labels it.
    let isDemo: Bool

    /// Creates a logged drink.
    ///
    /// - Parameters:
    ///   - id: The drink's identifier. A new drink gets a new one.
    ///   - type: Which drink.
    ///   - quantity: How many units of the drink's unit.
    ///   - milligrams: The total estimated caffeine, in milligrams.
    ///   - consumedAt: When the drink was consumed.
    ///   - isDemo: Whether the drink is part of the demo history. A drink the user logs isn't.
    init(
        id: UUID = UUID(), type: DrinkType, quantity: Int, milligrams: Double, consumedAt: Date, isDemo: Bool = false
    ) {
        self.id = id
        self.type = type
        self.quantity = quantity
        self.milligrams = milligrams
        self.consumedAt = consumedAt
        self.isDemo = isDemo
    }

    /// The caffeine this drink put into the body, for the decay model. It has the drink's `id`.
    var intake: CaffeineIntake {
        CaffeineIntake(id: id, milligrams: milligrams, consumedAt: consumedAt)
    }
}
