//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life GeneratedDrinkType
//

import FoundationModels

/// A drink from Half-Life's catalog, as the language model chooses it.
///
/// It mirrors ``DrinkType``, which can't be `@Generable` because Domain doesn't import FoundationModels (LMTOOL-9).
@Generable(description: "A drink from Half-Life's catalog.")
enum GeneratedDrinkType: CaseIterable {
    /// An espresso.
    case espresso
    /// An americano.
    case americano
    /// A latte.
    case latte
    /// A cappuccino.
    case cappuccino
    /// A flat white.
    case flatWhite
    /// Drip coffee.
    case dripCoffee
    /// Cold brew.
    case coldBrew
    /// Instant coffee.
    case instantCoffee
    /// Black tea.
    case blackTea
    /// Green tea.
    case greenTea
    /// Matcha.
    case matcha
    /// A cola.
    case cola
    /// An energy drink.
    case energyDrink

    /// The drink in the catalog that this mirrors.
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
