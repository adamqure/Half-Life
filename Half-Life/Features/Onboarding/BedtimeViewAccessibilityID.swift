//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BedtimeViewAccessibilityID
//

/// Accessibility identifiers for onboarding's bedtime step, shared with the UI test target.
enum BedtimeViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "bedtimeView.screen"
    /// The step's scrolling content.
    static let content = "bedtimeView.content"
    /// The bedtime's time picker.
    static let picker = "bedtimeView.picker"
    /// The button that saves and moves on.
    static let continueButton = "bedtimeView.continueButton"
}
