//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests OneTapFavourite
//

/// A one-tap favourite, by its place in the row, most logged first.
///
/// `TodayRobot` and `DrinkComposerRobot` both show the one-tap row, and take one of these to say which favourite.
enum OneTapFavourite: CaseIterable {
    case first, second, third

    /// The favourite's button's identifier, from `OneTapLogViewAccessibilityID`.
    var identifier: String {
        switch self {
        case .first: OneTapLogViewAccessibilityID.firstFavourite
        case .second: OneTapLogViewAccessibilityID.secondFavourite
        case .third: OneTapLogViewAccessibilityID.thirdFavourite
        }
    }
}
