//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkPresentation
//

import Foundation

extension DrinkType {
    /// The drink's name, as the composer lists it.
    var displayName: LocalizedStringResource {
        switch self {
        case .espresso: "Espresso"
        case .americano: "Americano"
        case .latte: "Latte"
        case .cappuccino: "Cappuccino"
        case .flatWhite: "Flat white"
        case .dripCoffee: "Drip coffee"
        case .coldBrew: "Cold brew"
        case .instantCoffee: "Instant coffee"
        case .blackTea: "Black tea"
        case .greenTea: "Green tea"
        case .matcha: "Matcha"
        case .cola: "Cola"
        case .energyDrink: "Energy drink"
        }
    }

    /// The SF Symbol shown beside the drink's name. It's decorative, because the name carries the meaning.
    var symbolName: String {
        switch self {
        case .espresso, .americano, .latte, .cappuccino, .flatWhite: "cup.and.saucer.fill"
        case .dripCoffee, .instantCoffee: "mug.fill"
        case .coldBrew, .cola: "takeoutbag.and.cup.and.straw.fill"
        case .blackTea, .greenTea: "cup.and.heat.waves.fill"
        case .matcha: "leaf.fill"
        case .energyDrink: "bolt.fill"
        }
    }

    /// The accessibility identifier of the drink's tile in the composer.
    var accessibilityTileIdentifier: String {
        switch self {
        case .espresso: DrinkComposerViewAccessibilityID.espressoTile
        case .americano: DrinkComposerViewAccessibilityID.americanoTile
        case .latte: DrinkComposerViewAccessibilityID.latteTile
        case .cappuccino: DrinkComposerViewAccessibilityID.cappuccinoTile
        case .flatWhite: DrinkComposerViewAccessibilityID.flatWhiteTile
        case .dripCoffee: DrinkComposerViewAccessibilityID.dripCoffeeTile
        case .coldBrew: DrinkComposerViewAccessibilityID.coldBrewTile
        case .instantCoffee: DrinkComposerViewAccessibilityID.instantCoffeeTile
        case .blackTea: DrinkComposerViewAccessibilityID.blackTeaTile
        case .greenTea: DrinkComposerViewAccessibilityID.greenTeaTile
        case .matcha: DrinkComposerViewAccessibilityID.matchaTile
        case .cola: DrinkComposerViewAccessibilityID.colaTile
        case .energyDrink: DrinkComposerViewAccessibilityID.energyDrinkTile
        }
    }
}

extension ServingUnit {
    /// A quantity with its unit, such as "2 shots". The String Catalog holds the plural forms.
    ///
    /// - Parameter quantity: How many units.
    func quantityText(_ quantity: Int) -> LocalizedStringResource {
        switch self {
        case .shot: "\(quantity) shots"
        case .cup: "\(quantity) cups"
        case .can: "\(quantity) cans"
        }
    }

    /// The caffeine in one unit, such as "63 mg per shot".
    ///
    /// - Parameter milligrams: The caffeine, already formatted with ``CaffeineFormat/milligrams(_:locale:)``.
    func perUnitText(milligrams: String) -> LocalizedStringResource {
        switch self {
        case .shot: "\(milligrams) per shot"
        case .cup: "\(milligrams) per cup"
        case .can: "\(milligrams) per can"
        }
    }
}

/// Formats caffeine amounts for display (constitution Article VII.3).
enum CaffeineFormat {
    /// Formats milligrams of caffeine for the locale, rounded to whole milligrams, such as "125 mg".
    ///
    /// The model keeps two decimal places. Presentation rounds for display (VIEW-2 in the Caffeine Decay Model
    /// article).
    ///
    /// - Parameters:
    ///   - milligrams: The amount of caffeine, in milligrams.
    ///   - locale: The locale to format for. Defaults to the user's.
    static func milligrams(_ milligrams: Double, locale: Locale = .autoupdatingCurrent) -> String {
        Measurement(value: milligrams, unit: UnitMass.milligrams)
            .formatted(
                Measurement<UnitMass>.FormatStyle(
                    width: .abbreviated, locale: locale, usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}
