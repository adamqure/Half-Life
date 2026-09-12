//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WelcomeViewAccessibilityID
//

/// Accessibility identifiers for onboarding's Welcome screen, shared with the UI test target.
enum WelcomeViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "welcomeView.screen"
    /// The screen's scrolling content.
    static let content = "welcomeView.content"
    /// The button that starts onboarding.
    static let getStartedButton = "welcomeView.getStartedButton"
}
