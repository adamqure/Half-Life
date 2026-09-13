//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppViewAccessibilityID
//

import Foundation

/// Accessibility identifiers for the root screen, shared with the UI test target.
enum AppViewAccessibilityID {
    /// The root screen's element, which robots use to detect the screen.
    static let screen = "appView.screen"
    /// The button that opens the drink composer.
    static let logButton = "appView.logButton"
}

/// The root screen's tabs, shared with the UI test target.
///
/// The system tab bar's buttons carry no accessibility identifier, so the root screen's robot finds each by its title
/// (constitution Article II.6). Each raw value is the title's key in `Localizable.xcstrings`, not its text, so the text
/// lives only in the catalog. ``AppView`` titles each tab with the key's text, and the robot looks the same key up in
/// the catalog, which also belongs to the UI test target.
enum AppTab: String, CaseIterable {
    /// The Today screen.
    case today = "appView.tab.today"
    /// The Insights tab.
    case insights = "appView.tab.insights"
    /// Settings.
    case settings = "appView.tab.settings"

    /// The tab's title, from the String Catalog.
    ///
    /// - Parameter bundle: The bundle whose catalog to read. The app reads its own. The UI tests read theirs, in the
    ///   development language.
    /// - Returns: The localized title.
    func title(in bundle: Bundle = .main) -> String {
        String(localized: String.LocalizationValue(rawValue), bundle: bundle)
    }
}
