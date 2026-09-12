//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionsViewAccessibilityID
//

/// Accessibility identifiers for onboarding's permissions step, shared with the UI test target.
enum PermissionsViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "permissionsView.screen"
    /// The step's scrolling content.
    static let content = "permissionsView.content"
    /// The Apple Health row's Allow button.
    static let healthAllowButton = "permissionsView.healthAllowButton"
    /// The Apple Health row's status.
    static let healthStatus = "permissionsView.healthStatus"
    /// The notifications row's Allow button.
    static let notificationsAllowButton = "permissionsView.notificationsAllowButton"
    /// The notifications row's status.
    static let notificationsStatus = "permissionsView.notificationsStatus"
    /// The notifications row's button to the Settings app.
    static let notificationsSettingsButton = "permissionsView.notificationsSettingsButton"
    /// The Face ID or Touch ID row's Allow button.
    static let biometricsAllowButton = "permissionsView.biometricsAllowButton"
    /// The Face ID or Touch ID row's status.
    static let biometricsStatus = "permissionsView.biometricsStatus"
    /// The Face ID or Touch ID row's button to the Settings app.
    static let biometricsSettingsButton = "permissionsView.biometricsSettingsButton"
    /// The button that moves on.
    static let continueButton = "permissionsView.continueButton"
}
