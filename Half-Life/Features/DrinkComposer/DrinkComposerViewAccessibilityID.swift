//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkComposerViewAccessibilityID
//

/// Accessibility identifiers for the drink composer, shared with the UI test target.
enum DrinkComposerViewAccessibilityID {
    /// The composer's root element, which robots use to detect the screen.
    static let screen = "drinkComposerView.screen"
    /// The button that closes the composer without logging.
    static let closeButton = "drinkComposerView.closeButton"
    /// The row of drink tiles, which scrolls sideways.
    static let drinkTiles = "drinkComposerView.drinkTiles"

    /// The espresso tile.
    static let espressoTile = "drinkComposerView.espressoTile"
    /// The americano tile.
    static let americanoTile = "drinkComposerView.americanoTile"
    /// The latte tile.
    static let latteTile = "drinkComposerView.latteTile"
    /// The cappuccino tile.
    static let cappuccinoTile = "drinkComposerView.cappuccinoTile"
    /// The flat white tile.
    static let flatWhiteTile = "drinkComposerView.flatWhiteTile"
    /// The drip coffee tile.
    static let dripCoffeeTile = "drinkComposerView.dripCoffeeTile"
    /// The cold brew tile.
    static let coldBrewTile = "drinkComposerView.coldBrewTile"
    /// The instant coffee tile.
    static let instantCoffeeTile = "drinkComposerView.instantCoffeeTile"
    /// The black tea tile.
    static let blackTeaTile = "drinkComposerView.blackTeaTile"
    /// The green tea tile.
    static let greenTeaTile = "drinkComposerView.greenTeaTile"
    /// The matcha tile.
    static let matchaTile = "drinkComposerView.matchaTile"
    /// The cola tile.
    static let colaTile = "drinkComposerView.colaTile"
    /// The energy drink tile.
    static let energyDrinkTile = "drinkComposerView.energyDrinkTile"

    /// The chosen drink's estimated caffeine.
    static let estimate = "drinkComposerView.estimate"
    /// The chosen drink's quantity, with its unit.
    static let quantity = "drinkComposerView.quantity"
    /// The button that removes one unit.
    static let decreaseButton = "drinkComposerView.decreaseButton"
    /// The button that adds one unit.
    static let increaseButton = "drinkComposerView.increaseButton"
    /// The "Now" choice.
    static let whenNow = "drinkComposerView.whenNow"
    /// The "1h ago" choice.
    static let whenOneHourAgo = "drinkComposerView.whenOneHourAgo"
    /// The "2h ago" choice.
    static let whenTwoHoursAgo = "drinkComposerView.whenTwoHoursAgo"
    /// The "4h ago" choice.
    static let whenFourHoursAgo = "drinkComposerView.whenFourHoursAgo"
    /// The message shown when the drink couldn't be saved.
    static let errorMessage = "drinkComposerView.errorMessage"
    /// The button that logs the chosen drink.
    static let addButton = "drinkComposerView.addButton"
}
