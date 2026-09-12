//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkTypeTests
//

import Testing

@testable import Half_Life

/// Checks the drink catalog against the Drink Composer article: requirements TYPE-1 to TYPE-4.
struct DrinkTypeTests {

    /// Rounds to two decimal places, the precision the model is specified to.
    static func rounded(_ milligrams: Double) -> Double {
        (milligrams * 100).rounded() / 100
    }

    /// One row of the article's catalog table.
    struct CatalogRow: Sendable {
        let drink: DrinkType
        let unit: ServingUnit
        let milligramsPerUnit: Double
        let defaultQuantity: Int
    }

    /// The Drink Composer article's catalog table.
    static let catalog = [
        CatalogRow(drink: .espresso, unit: .shot, milligramsPerUnit: 62.7, defaultQuantity: 1),
        CatalogRow(drink: .americano, unit: .shot, milligramsPerUnit: 62.7, defaultQuantity: 2),
        CatalogRow(drink: .latte, unit: .shot, milligramsPerUnit: 62.7, defaultQuantity: 2),
        CatalogRow(drink: .cappuccino, unit: .shot, milligramsPerUnit: 62.7, defaultQuantity: 2),
        CatalogRow(drink: .flatWhite, unit: .shot, milligramsPerUnit: 62.7, defaultQuantity: 2),
        CatalogRow(drink: .dripCoffee, unit: .cup, milligramsPerUnit: 94.6, defaultQuantity: 1),
        CatalogRow(drink: .coldBrew, unit: .cup, milligramsPerUnit: 102.5, defaultQuantity: 2),
        CatalogRow(drink: .instantCoffee, unit: .cup, milligramsPerUnit: 61.5, defaultQuantity: 1),
        CatalogRow(drink: .blackTea, unit: .cup, milligramsPerUnit: 47.3, defaultQuantity: 1),
        CatalogRow(drink: .greenTea, unit: .cup, milligramsPerUnit: 28.4, defaultQuantity: 1),
        CatalogRow(drink: .matcha, unit: .cup, milligramsPerUnit: 63.3, defaultQuantity: 1),
        CatalogRow(drink: .cola, unit: .can, milligramsPerUnit: 34, defaultQuantity: 1),
        CatalogRow(drink: .energyDrink, unit: .can, milligramsPerUnit: 80, defaultQuantity: 1),
    ]

    // MARK: - TYPE-1: every drink matches the catalog

    @Test(arguments: catalog)
    func matchesTheCatalog(row: CatalogRow) {
        #expect(row.drink.unit == row.unit)
        #expect(row.drink.milligramsPerUnit == row.milligramsPerUnit)
        #expect(row.drink.defaultQuantity == row.defaultQuantity)
    }

    @Test func catalogCoversEveryDrink() {
        #expect(Self.catalog.map(\.drink) == DrinkType.allCases)
    }

    // MARK: - TYPE-2: raw values are stored, so they never change

    @Test func rawValuesArePinnedInDisplayOrder() {
        let pinned = [
            "espresso", "americano", "latte", "cappuccino", "flatWhite", "dripCoffee", "coldBrew", "instantCoffee",
            "blackTea", "greenTea", "matcha", "cola", "energyDrink",
        ]

        #expect(DrinkType.allCases.map(\.rawValue) == pinned)
    }

    // MARK: - TYPE-3: every drink can be logged

    @Test(arguments: DrinkType.allCases)
    func defaultsToAtLeastOneUnitWithSomeCaffeine(drink: DrinkType) {
        #expect(drink.defaultQuantity >= 1)
        #expect(drink.milligramsPerUnit > 0)
    }

    // MARK: - TYPE-4: the estimate is caffeine per unit × quantity

    @Test func latteAtTwoShotsIsTheWorkedExample() {
        #expect(Self.rounded(DrinkType.latte.estimatedMilligrams(quantity: 2)) == 125.40)
    }

    @Test func coldBrewAtTwoCupsIsTheWorkedExample() {
        #expect(Self.rounded(DrinkType.coldBrew.estimatedMilligrams(quantity: 2)) == 205.00)
    }

    @Test(arguments: DrinkType.allCases, [1, 3])
    func estimateScalesWithQuantity(drink: DrinkType, quantity: Int) {
        #expect(drink.estimatedMilligrams(quantity: quantity) == drink.milligramsPerUnit * Double(quantity))
    }
}
