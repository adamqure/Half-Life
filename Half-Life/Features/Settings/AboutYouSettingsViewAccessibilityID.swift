//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AboutYouSettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' About you screen, shared with the UI test target.
enum AboutYouSettingsViewAccessibilityID {
    /// The screen's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "aboutYouSettingsView.screen"
    /// The name field.
    static let nameField = "aboutYouSettingsView.nameField"
    /// The age wheel.
    static let agePicker = "aboutYouSettingsView.agePicker"
}
