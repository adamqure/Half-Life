//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FavouriteDrink
//

/// A drink the user can log in one tap: a drink and the quantity it's logged at.
///
/// ``FavouriteDrinksRule`` finds the user's most common ones from the drink log. "Latte, 2 shots" and "Latte, 3 shots"
/// are different favourites. See the One-Tap Log article.
struct FavouriteDrink: Hashable, Sendable {
    /// Which drink.
    let type: DrinkType
    /// How many units of the drink's ``DrinkType/unit`` one tap logs. At least 1.
    let quantity: Int
}
