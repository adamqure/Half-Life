//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ServingUnit
//

/// What a drink's quantity counts. See the Drink Composer article.
enum ServingUnit: Sendable, Equatable {
    /// One espresso shot, 1 US fl oz (about 30 mL).
    case shot
    /// 8 US fl oz (about 237 mL) of brewed coffee or tea. For matcha, one drink made with a level teaspoon of powder.
    case cup
    /// The drink's standard can, which differs by drink.
    case can
}
