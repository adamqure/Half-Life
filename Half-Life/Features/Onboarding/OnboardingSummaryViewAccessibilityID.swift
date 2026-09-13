//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingSummaryViewAccessibilityID
//

/// Accessibility identifiers for onboarding's summary, shared with the UI test target.
enum OnboardingSummaryViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "onboardingSummaryView.screen"
    /// The summary's scrolling content.
    static let content = "onboardingSummaryView.content"
    /// The heading, which names the user when it knows their name.
    static let title = "onboardingSummaryView.title"
    /// The bedtime.
    static let bedtime = "onboardingSummaryView.bedtime"
    /// The recommended sleep.
    static let recommendedSleep = "onboardingSummaryView.recommendedSleep"
    /// The button that finishes onboarding and opens the drink composer.
    static let logFirstCupButton = "onboardingSummaryView.logFirstCupButton"
    /// The button that finishes onboarding.
    static let takeMeToTodayButton = "onboardingSummaryView.takeMeToTodayButton"
}
