//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkPresentationTests
//

import Foundation
import Testing
import UIKit

@testable import Half_Life

/// Checks how drinks are presented against the Drink Composer article: requirements SHOW-1 to SHOW-5.
struct DrinkPresentationTests {

    static let enUS = Locale(identifier: "en_US")

    // MARK: - SHOW-1: every drink has the icon from the iconography table

    @Test func iconsMatchTheIconographyTable() {
        let expected: [DrinkType: String] = [
            .espresso: "cup.and.saucer.fill", .americano: "cup.and.saucer.fill", .latte: "cup.and.saucer.fill",
            .cappuccino: "cup.and.saucer.fill", .flatWhite: "cup.and.saucer.fill", .dripCoffee: "mug.fill",
            .coldBrew: "takeoutbag.and.cup.and.straw.fill", .instantCoffee: "mug.fill",
            .blackTea: "cup.and.heat.waves.fill", .greenTea: "cup.and.heat.waves.fill", .matcha: "leaf.fill",
            .cola: "takeoutbag.and.cup.and.straw.fill", .energyDrink: "bolt.fill",
        ]

        #expect(Dictionary(uniqueKeysWithValues: DrinkType.allCases.map { ($0, $0.symbolName) }) == expected)
    }

    @Test(arguments: DrinkType.allCases)
    func everyIconIsASystemSymbol(drink: DrinkType) {
        #expect(UIImage(systemName: drink.symbolName) != nil)
    }

    // MARK: - SHOW-2: every drink has its own name

    @Test func everyDrinkHasItsOwnName() {
        let names = DrinkType.allCases.map { String(localized: $0.displayName) }

        #expect(
            names == [
                "Espresso", "Americano", "Latte", "Cappuccino", "Flat white", "Drip coffee", "Cold brew",
                "Instant coffee", "Black tea", "Green tea", "Matcha", "Cola", "Energy drink",
            ])
    }

    // MARK: - SHOW-3: every drink tile has its own accessibility identifier

    @Test func everyDrinkTileHasItsOwnIdentifier() {
        let identifiers = DrinkType.allCases.map(\.accessibilityTileIdentifier)

        #expect(Set(identifiers).count == DrinkType.allCases.count)
        #expect(DrinkType.latte.accessibilityTileIdentifier == DrinkComposerViewAccessibilityID.latteTile)
    }

    // MARK: - SHOW-4: quantities and units are pluralized

    /// A quantity of a unit, and the text it should read as.
    struct QuantityText: Sendable {
        let unit: ServingUnit
        let quantity: Int
        let expected: String
    }

    @Test(
        arguments: [
            QuantityText(unit: .shot, quantity: 1, expected: "1 shot"),
            QuantityText(unit: .shot, quantity: 2, expected: "2 shots"),
            QuantityText(unit: .cup, quantity: 1, expected: "1 cup"),
            QuantityText(unit: .cup, quantity: 3, expected: "3 cups"),
            QuantityText(unit: .can, quantity: 1, expected: "1 can"),
            QuantityText(unit: .can, quantity: 2, expected: "2 cans"),
        ])
    func quantityTextIsPluralized(_ example: QuantityText) {
        #expect(String(localized: example.unit.quantityText(example.quantity)) == example.expected)
    }

    @Test(
        arguments: [(ServingUnit.shot, "63 mg per shot"), (.cup, "63 mg per cup"), (.can, "63 mg per can")]
            as [(ServingUnit, String)])
    func perUnitTextNamesTheUnit(unit: ServingUnit, expected: String) {
        #expect(String(localized: unit.perUnitText(milligrams: "63 mg")) == expected)
    }

    // MARK: - SHOW-5: caffeine is shown in whole milligrams, formatted for the locale

    @Test(arguments: [(125.4, "125 mg"), (62.7, "63 mg"), (1_234.4, "1,234 mg")] as [(Double, String)])
    func milligramsAreWholeNumbersForTheLocale(milligrams: Double, expected: String) {
        #expect(CaffeineFormat.milligrams(milligrams, locale: Self.enUS) == expected)
    }
}
