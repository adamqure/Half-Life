//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkTypeAppEnum
//

import AppIntents

/// The drink catalog as Siri and Shortcuts see it: one case per ``DrinkType``, with the same raw values.
///
/// Domain can't import App Intents, so this mirrors ``DrinkType``. The exhaustive switches in ``init(_:)`` and
/// ``drinkType`` stop the build when a drink isn't mirrored. Each case shows the composer's name for its drink, under
/// the same String Catalog key. See INTENT-ENUM-1 and INTENT-ENUM-2 in the App Intents article.
enum DrinkTypeAppEnum: String, AppEnum {
    /// ``DrinkType/espresso``.
    case espresso
    /// ``DrinkType/americano``.
    case americano
    /// ``DrinkType/latte``.
    case latte
    /// ``DrinkType/cappuccino``.
    case cappuccino
    /// ``DrinkType/flatWhite``.
    case flatWhite
    /// ``DrinkType/dripCoffee``.
    case dripCoffee
    /// ``DrinkType/coldBrew``.
    case coldBrew
    /// ``DrinkType/instantCoffee``.
    case instantCoffee
    /// ``DrinkType/blackTea``.
    case blackTea
    /// ``DrinkType/greenTea``.
    case greenTea
    /// ``DrinkType/matcha``.
    case matcha
    /// ``DrinkType/cola``.
    case cola
    /// ``DrinkType/energyDrink``.
    case energyDrink

    /// What Siri and Shortcuts call a drink.
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Drink"

    /// Each case's name: the composer's name for its drink.
    static let caseDisplayRepresentations: [DrinkTypeAppEnum: DisplayRepresentation] = [
        .espresso: "Espresso",
        .americano: "Americano",
        .latte: "Latte",
        .cappuccino: "Cappuccino",
        .flatWhite: "Flat white",
        .dripCoffee: "Drip coffee",
        .coldBrew: "Cold brew",
        .instantCoffee: "Instant coffee",
        .blackTea: "Black tea",
        .greenTea: "Green tea",
        .matcha: "Matcha",
        .cola: "Cola",
        .energyDrink: "Energy drink",
    ]

    /// The case for a drink.
    ///
    /// - Parameter type: The drink.
    init(_ type: DrinkType) {
        self = type.appEnum
    }

    /// The drink this case stands for.
    var drinkType: DrinkType {
        switch self {
        case .espresso: .espresso
        case .americano: .americano
        case .latte: .latte
        case .cappuccino: .cappuccino
        case .flatWhite: .flatWhite
        case .dripCoffee: .dripCoffee
        case .coldBrew: .coldBrew
        case .instantCoffee: .instantCoffee
        case .blackTea: .blackTea
        case .greenTea: .greenTea
        case .matcha: .matcha
        case .cola: .cola
        case .energyDrink: .energyDrink
        }
    }
}

extension DrinkType {
    /// The drink's case in ``DrinkTypeAppEnum``. The exhaustive switch stops the build when a drink isn't mirrored.
    fileprivate var appEnum: DrinkTypeAppEnum {
        switch self {
        case .espresso: .espresso
        case .americano: .americano
        case .latte: .latte
        case .cappuccino: .cappuccino
        case .flatWhite: .flatWhite
        case .dripCoffee: .dripCoffee
        case .coldBrew: .coldBrew
        case .instantCoffee: .instantCoffee
        case .blackTea: .blackTea
        case .greenTea: .greenTea
        case .matcha: .matcha
        case .cola: .cola
        case .energyDrink: .energyDrink
        }
    }
}
