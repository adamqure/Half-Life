//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockSettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' App lock screen and its section, shared with the UI test target.
enum AppLockSettingsViewAccessibilityID {
    /// The screen's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "appLockSettingsView.screen"
    /// The option that turns the app lock on or off.
    static let appLockOption = "appLockSettingsView.appLockOption"
    /// The message that the last change to the app lock failed.
    static let appLockError = "appLockSettingsView.appLockError"
}
