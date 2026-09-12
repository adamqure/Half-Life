//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LoggedDrinkTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks a logged drink against the Drink Composer article: requirements DRINK-1 and DRINK-2.
struct LoggedDrinkTests {

    let consumedAt = Date(timeIntervalSinceReferenceDate: 0)

    // MARK: - DRINK-1: a logged drink comes down to one caffeine intake

    @Test func intakeCarriesTheDrinksIDAmountAndTime() {
        let drink = LoggedDrink(type: .latte, quantity: 2, milligrams: 125.4, consumedAt: consumedAt)

        #expect(drink.intake == CaffeineIntake(id: drink.id, milligrams: 125.4, consumedAt: consumedAt))
    }

    // MARK: - DRINK-2: a new drink gets a new ID by default

    @Test func eachNewDrinkGetsItsOwnID() {
        let first = LoggedDrink(type: .espresso, quantity: 1, milligrams: 62.7, consumedAt: consumedAt)
        let second = LoggedDrink(type: .espresso, quantity: 1, milligrams: 62.7, consumedAt: consumedAt)

        #expect(first.id != second.id)
    }

    @Test func keepsAGivenID() {
        let id = UUID()

        #expect(LoggedDrink(id: id, type: .cola, quantity: 1, milligrams: 34, consumedAt: consumedAt).id == id)
    }
}
