//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SiriShortcutsViewAccessibilityID
//

/// Accessibility identifiers for onboarding's "Use Siri and Shortcuts" step, shared with the UI test target.
enum SiriShortcutsViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "siriShortcutsView.screen"
    /// The step's scrolling content.
    static let content = "siriShortcutsView.content"
    /// The phrase to try for logging a drink.
    static let logPhrase = "siriShortcutsView.logPhrase"
    /// The phrase to try for the caffeine level.
    static let levelPhrase = "siriShortcutsView.levelPhrase"
    /// The phrase to try for the sleep time.
    static let sleepPhrase = "siriShortcutsView.sleepPhrase"
    /// The phrase to try for asking a question.
    static let askPhrase = "siriShortcutsView.askPhrase"
    /// The button that opens Half-Life's shortcuts in the Shortcuts app.
    static let shortcutsLink = "siriShortcutsView.shortcutsLink"
    /// The button that moves on.
    static let continueButton = "siriShortcutsView.continueButton"
}
