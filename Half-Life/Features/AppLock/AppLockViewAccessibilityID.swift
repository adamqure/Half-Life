//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockViewAccessibilityID
//

/// Accessibility identifiers for the lock screen, shared with the UI test target (constitution Article II.7).
enum AppLockViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "appLockView.screen"
    /// The button that asks to unlock the app.
    static let unlockButton = "appLockView.unlockButton"
}
