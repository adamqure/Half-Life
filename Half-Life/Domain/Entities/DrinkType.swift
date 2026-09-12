//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkType
//

/// A kind of caffeinated drink the app can log.
///
/// The cases are the drink catalog, in the order the composer lists them. Each raw value is stored with every
/// logged drink, so a case is never renamed or removed once shipped. The Drink Composer article gives each
/// estimate's source.
enum DrinkType: String, CaseIterable, Sendable {
    /// A shot of espresso on its own.
    case espresso
    /// Espresso topped up with hot water.
    case americano
    /// Espresso with steamed milk.
    case latte
    /// Espresso with steamed milk and foam.
    case cappuccino
    /// Espresso with a thin layer of steamed milk.
    case flatWhite
    /// Brewed coffee, such as drip or French press.
    case dripCoffee
    /// Coffee steeped cold.
    case coldBrew
    /// Coffee made from instant powder.
    case instantCoffee
    /// Brewed black tea.
    case blackTea
    /// Brewed green tea.
    case greenTea
    /// Matcha made with powdered green tea.
    case matcha
    /// Caffeinated cola.
    case cola
    /// An energy drink.
    case energyDrink

    /// What the drink's quantity counts.
    var unit: ServingUnit {
        switch self {
        case .espresso, .americano, .latte, .cappuccino, .flatWhite: .shot
        case .dripCoffee, .coldBrew, .instantCoffee, .blackTea, .greenTea, .matcha: .cup
        case .cola, .energyDrink: .can
        }
    }

    /// The estimated caffeine in one unit, in milligrams. Always greater than zero.
    var milligramsPerUnit: Double {
        switch self {
        case .espresso, .americano, .latte, .cappuccino, .flatWhite: 62.7
        case .dripCoffee: 94.6
        case .coldBrew: 102.5
        case .instantCoffee: 61.5
        case .blackTea: 47.3
        case .greenTea: 28.4
        case .matcha: 63.3
        case .cola: 34
        case .energyDrink: 80
        }
    }

    /// The quantity the composer starts at. At least 1.
    var defaultQuantity: Int {
        switch self {
        case .americano, .latte, .cappuccino, .flatWhite, .coldBrew: 2
        case .espresso, .dripCoffee, .instantCoffee, .blackTea, .greenTea, .matcha, .cola, .energyDrink: 1
        }
    }

    /// Returns the estimated caffeine in `quantity` units of the drink: ``milligramsPerUnit`` × `quantity`.
    ///
    /// - Parameter quantity: How many units of the drink's ``unit``.
    /// - Returns: The estimated caffeine, in milligrams.
    func estimatedMilligrams(quantity: Int) -> Double {
        milligramsPerUnit * Double(quantity)
    }
}
