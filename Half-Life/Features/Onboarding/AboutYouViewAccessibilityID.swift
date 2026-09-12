//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AboutYouViewAccessibilityID
//

/// Accessibility identifiers for onboarding's About you step, shared with the UI test target.
enum AboutYouViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "aboutYouView.screen"
    /// The step's scrolling content.
    static let content = "aboutYouView.content"
    /// The first name field.
    static let nameField = "aboutYouView.nameField"
    /// The age picker.
    static let agePicker = "aboutYouView.agePicker"
    /// The button that saves and moves on.
    static let continueButton = "aboutYouView.continueButton"
}
