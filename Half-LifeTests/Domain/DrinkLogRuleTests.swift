//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the rule that decides what may be logged against the Drink Composer article: requirements LOGRULE-1 to
/// LOGRULE-4.
struct DrinkLogRuleTests {

    let rule = DrinkLogRule()
    let now = Date(timeIntervalSinceReferenceDate: 0)

    func drink(quantity: Int = 1, consumedAt: Date) -> LoggedDrink {
        LoggedDrink(
            type: .espresso, quantity: quantity, milligrams: DrinkType.espresso.estimatedMilligrams(quantity: quantity),
            consumedAt: consumedAt)
    }

    // MARK: - LOGRULE-1: a quantity below 1 is rejected

    @Test(arguments: [0, -1])
    func rejectsAQuantityBelowOne(quantity: Int) {
        #expect(throws: DrinkLogRule.Violation.quantityBelowOne) {
            try rule.validate(drink(quantity: quantity, consumedAt: now), now: now)
        }
    }

    // MARK: - LOGRULE-2: a drink consumed in the future is rejected

    @Test func rejectsADrinkConsumedAfterNow() {
        #expect(throws: DrinkLogRule.Violation.consumedInFuture) {
            try rule.validate(drink(consumedAt: now.addingTimeInterval(1)), now: now)
        }
    }

    // MARK: - LOGRULE-3: a drink consumed now or earlier is accepted

    @Test(arguments: [0, -60, -4 * 3_600] as [TimeInterval])
    func acceptsADrinkConsumedNowOrEarlier(offset: TimeInterval) throws {
        try rule.validate(drink(consumedAt: now.addingTimeInterval(offset)), now: now)
    }

    // MARK: - LOGRULE-4: the quantity is checked first

    @Test func reportsTheQuantityWhenBothAreWrong() {
        #expect(throws: DrinkLogRule.Violation.quantityBelowOne) {
            try rule.validate(drink(quantity: 0, consumedAt: now.addingTimeInterval(60)), now: now)
        }
    }
}
