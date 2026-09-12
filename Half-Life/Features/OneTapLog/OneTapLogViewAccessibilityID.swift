//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OneTapLogViewAccessibilityID
//

/// Accessibility identifiers for ``OneTapLogView`` (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and the robots of the screens
/// that show it, `TodayRobot` and `DrinkComposerRobot`, share one definition. The row has no robot of its own, so it
/// has no `screen` identifier. Each robot looks for these identifiers only inside its own screen, because the Today
/// screen and the composer both show the row.
enum OneTapLogViewAccessibilityID {
    /// The most logged favourite's button.
    static let firstFavourite = "oneTapLogView.firstFavourite"
    /// The second favourite's button.
    static let secondFavourite = "oneTapLogView.secondFavourite"
    /// The third favourite's button.
    static let thirdFavourite = "oneTapLogView.thirdFavourite"

    /// The favourites' buttons, in the row's order.
    static let favourites = [firstFavourite, secondFavourite, thirdFavourite]
}
