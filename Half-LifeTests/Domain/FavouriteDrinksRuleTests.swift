//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FavouriteDrinksRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the rule that picks the one-tap favourites against the One-Tap Log article: requirements FAV-1 to FAV-5.
struct FavouriteDrinksRuleTests {

    let rule = FavouriteDrinksRule()
    let now = Date(timeIntervalSinceReferenceDate: 100_000)

    /// `quantity` units of `type`, consumed `minutesAgo` minutes before `now`.
    func drink(_ type: DrinkType, _ quantity: Int, minutesAgo: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
            consumedAt: now.addingTimeInterval(-minutesAgo * 60))
    }

    func favourite(_ type: DrinkType, _ quantity: Int) -> FavouriteDrink {
        FavouriteDrink(type: type, quantity: quantity)
    }

    /// `count` drinks of one unit of `type`, one a minute, the latest consumed `minutesAgo` minutes before `now`.
    func drinks(_ type: DrinkType, count: Int, minutesAgo: Double) -> [LoggedDrink] {
        (0..<count).map { drink(type, 1, minutesAgo: minutesAgo + Double($0)) }
    }

    // MARK: - FAV-1: drinks are counted by type and quantity together, most logged first, three at most

    @Test func countsTheDrinkAndItsQuantityTogether() {
        let drinks = [
            drink(.latte, 2, minutesAgo: 600), drink(.latte, 3, minutesAgo: 500), drink(.latte, 2, minutesAgo: 400),
            drink(.cola, 1, minutesAgo: 300), drink(.cola, 1, minutesAgo: 200), drink(.cola, 1, minutesAgo: 100),
        ]

        #expect(rule.favourites(from: drinks) == [favourite(.cola, 1), favourite(.latte, 2), favourite(.latte, 3)])
    }

    @Test func keepsOnlyTheThreeMostLogged() {
        var drinks = self.drinks(.matcha, count: 4, minutesAgo: 1)
        drinks += self.drinks(.greenTea, count: 3, minutesAgo: 10)
        drinks += self.drinks(.blackTea, count: 2, minutesAgo: 20)
        drinks.append(drink(.cola, 1, minutesAgo: 0))

        #expect(
            rule.favourites(from: drinks) == [favourite(.matcha, 1), favourite(.greenTea, 1), favourite(.blackTea, 1)])
    }

    // MARK: - FAV-2: a tie goes to the favourite consumed most recently

    @Test func aTieGoesToTheOneConsumedMostRecently() {
        let drinks = [
            drink(.matcha, 1, minutesAgo: 900), drink(.greenTea, 1, minutesAgo: 800),
            drink(.greenTea, 1, minutesAgo: 20), drink(.matcha, 1, minutesAgo: 10),
        ]

        #expect(rule.favourites(from: drinks).prefix(2) == [favourite(.matcha, 1), favourite(.greenTea, 1)])
    }

    @Test func theOrderOfTheDrinksGivenDoesntMatter() {
        let drinks = [
            drink(.matcha, 1, minutesAgo: 900), drink(.greenTea, 1, minutesAgo: 800),
            drink(.greenTea, 1, minutesAgo: 20), drink(.matcha, 1, minutesAgo: 10), drink(.cola, 1, minutesAgo: 5),
        ]

        #expect(rule.favourites(from: drinks.reversed()) == rule.favourites(from: drinks))
    }

    @Test func aTieAtTheSameMomentGoesToCatalogOrderThenTheSmallerQuantity() {
        let drinks = [drink(.cola, 1, minutesAgo: 5), drink(.latte, 3, minutesAgo: 5), drink(.latte, 2, minutesAgo: 5)]

        #expect(rule.favourites(from: drinks) == [favourite(.latte, 2), favourite(.latte, 3), favourite(.cola, 1)])
    }

    // MARK: - FAV-3: every drink ever logged counts

    @Test func drinksFromLongAgoCountAsMuchAsRecentOnes() {
        let yearAndAMonthAgo: Double = 400 * 24 * 60
        var drinks = self.drinks(.energyDrink, count: 3, minutesAgo: yearAndAMonthAgo)
        drinks += [drink(.latte, 2, minutesAgo: 60), drink(.latte, 2, minutesAgo: 30)]

        #expect(rule.favourites(from: drinks).prefix(2) == [favourite(.energyDrink, 1), favourite(.latte, 2)])
    }

    // MARK: - FAV-4: slots the log can't fill take the starters, in order, skipping any already there

    @Test func slotsTheLogCantFillTakeTheStarters() {
        let drinks = [drink(.matcha, 1, minutesAgo: 30)]

        #expect(
            rule.favourites(from: drinks) == [favourite(.matcha, 1), favourite(.espresso, 2), favourite(.flatWhite, 2)])
    }

    @Test func aStarterThatsAlreadyAFavouriteIsSkipped() {
        let drinks = [drink(.espresso, 2, minutesAgo: 60), drink(.cola, 1, minutesAgo: 30)]

        #expect(
            rule.favourites(from: drinks) == [favourite(.cola, 1), favourite(.espresso, 2), favourite(.flatWhite, 2)])
    }

    // MARK: - FAV-5: with nothing logged, the favourites are the starters

    @Test func withNothingLoggedTheFavouritesAreTheStarters() {
        #expect(rule.favourites(from: []) == FavouriteDrinksRule.starters)
    }

    @Test func theStartersAreThePrototypesThreeDrinks() {
        let prototypes = [favourite(.espresso, 2), favourite(.flatWhite, 2), favourite(.coldBrew, 2)]

        #expect(FavouriteDrinksRule.starters == prototypes)
    }
}
