//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' root list, shared with the UI test target (constitution Article II.7).
///
/// Each screen a row opens has its own `…AccessibilityID` file.
enum SettingsViewAccessibilityID {
    /// The root's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "settingsView.screen"
    /// The row that opens About you.
    static let aboutYouRow = "settingsView.aboutYouRow"
    /// The row that opens Caffeine and your body.
    static let halfLifeFactorsRow = "settingsView.halfLifeFactorsRow"
    /// The row that opens Bedtime.
    static let bedtimeRow = "settingsView.bedtimeRow"
    /// The row that opens Permissions.
    static let permissionsRow = "settingsView.permissionsRow"
    /// The row that opens App lock.
    static let appLockRow = "settingsView.appLockRow"
    /// The row that opens Demo data.
    static let demoDataRow = "settingsView.demoDataRow"
    /// The root's last line: the app's version and build.
    static let appVersion = "settingsView.appVersion"
}
