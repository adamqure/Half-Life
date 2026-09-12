//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FavouriteDrinksRule
//

import Foundation

/// The business rule that picks the one-tap favourites from the drink log.
///
/// It counts every drink ever logged by drink and quantity together, and ranks the most logged first. A tie goes to
/// the favourite consumed most recently, then to catalog order, then to the smaller quantity. When the log has fewer
/// than ``count`` favourites, the ``starters`` fill the rest, in order, skipping any already there. It holds no state
/// and reads no clock. ``FavouriteDrinksRepository`` executes it. See the One-Tap Log article.
struct FavouriteDrinksRule: Sendable {
    /// How many favourites there are.
    static let count = 3

    /// The drinks that fill the slots the log can't: the prototype's three one-tap drinks, with 2 espresso shots
    /// for its double espresso.
    static let starters: [FavouriteDrink] = [
        FavouriteDrink(type: .espresso, quantity: 2),
        FavouriteDrink(type: .flatWhite, quantity: 2),
        FavouriteDrink(type: .coldBrew, quantity: 2),
    ]

    /// How often a favourite was logged, and when it was last consumed.
    private struct Tally {
        var count: Int
        var lastConsumedAt: Date
    }

    /// Returns the ``count`` favourites for `drinks`, first first.
    ///
    /// - Parameter drinks: Every logged drink, in any order.
    /// - Returns: The favourites: the most logged, then the starters the log can't replace.
    func favourites(from drinks: [LoggedDrink]) -> [FavouriteDrink] {
        var tallies: [FavouriteDrink: Tally] = [:]
        for drink in drinks {
            let favourite = FavouriteDrink(type: drink.type, quantity: drink.quantity)
            var tally = tallies[favourite, default: Tally(count: 0, lastConsumedAt: drink.consumedAt)]
            tally.count += 1
            tally.lastConsumedAt = max(tally.lastConsumedAt, drink.consumedAt)
            tallies[favourite] = tally
        }
        let logged = tallies.sorted(by: Self.ranksFirst).prefix(Self.count).map(\.key)
        let starters = Self.starters.filter { !logged.contains($0) }
        return Array((logged + starters).prefix(Self.count))
    }

    private static func ranksFirst(
        _ lhs: (key: FavouriteDrink, value: Tally), _ rhs: (key: FavouriteDrink, value: Tally)
    ) -> Bool {
        if lhs.value.count != rhs.value.count {
            return lhs.value.count > rhs.value.count
        }
        if lhs.value.lastConsumedAt != rhs.value.lastConsumedAt {
            return lhs.value.lastConsumedAt > rhs.value.lastConsumedAt
        }
        if lhs.key.type != rhs.key.type {
            return catalogPosition(of: lhs.key.type) < catalogPosition(of: rhs.key.type)
        }
        return lhs.key.quantity < rhs.key.quantity
    }

    /// The drink's place in the catalog. Every drink is in `allCases`, so the fallback is never used.
    private static func catalogPosition(of type: DrinkType) -> Int {
        DrinkType.allCases.firstIndex(of: type) ?? DrinkType.allCases.count
    }
}
