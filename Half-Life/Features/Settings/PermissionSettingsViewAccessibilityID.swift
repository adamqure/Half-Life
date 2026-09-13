//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionSettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' Permissions screen, shared with the UI test target.
enum PermissionSettingsViewAccessibilityID {
    /// The screen's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "permissionSettingsView.screen"
    /// The Apple Health card's Allow button.
    static let healthAllowButton = "permissionSettingsView.healthAllowButton"
    /// The Apple Health card's status.
    static let healthStatus = "permissionSettingsView.healthStatus"
    /// The notifications card's Allow button.
    static let notificationsAllowButton = "permissionSettingsView.notificationsAllowButton"
    /// The notifications card's status.
    static let notificationsStatus = "permissionSettingsView.notificationsStatus"
    /// The notifications card's button to the Settings app.
    static let notificationsSettingsButton = "permissionSettingsView.notificationsSettingsButton"
    /// The Face ID or Touch ID card's Allow button.
    static let biometricsAllowButton = "permissionSettingsView.biometricsAllowButton"
    /// The Face ID or Touch ID card's status.
    static let biometricsStatus = "permissionSettingsView.biometricsStatus"
    /// The Face ID or Touch ID card's button to the Settings app.
    static let biometricsSettingsButton = "permissionSettingsView.biometricsSettingsButton"
}
