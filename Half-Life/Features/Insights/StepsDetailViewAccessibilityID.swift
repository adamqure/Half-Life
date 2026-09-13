//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepsDetailViewAccessibilityID
//

/// Accessibility identifiers for ``StepsDetailView`` (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and `StepsDetailRobot` share
/// one definition.
enum StepsDetailViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "stepsDetailView.screen"
    /// The screen's title, "Steps".
    static let title = "stepsDetailView.title"
    /// The verdict: what the comparison can honestly say.
    static let verdict = "stepsDetailView.verdict"
    /// The average steps on days after a caffeine night, and how many days.
    static let afterCaffeine = "stepsDetailView.afterCaffeine"
    /// The average steps on the other days, and how many days.
    static let otherDays = "stepsDetailView.otherDays"
    /// The sentence that says what a caffeine night is.
    static let definition = "stepsDetailView.definition"
    /// The chart of each day's steps.
    static let chart = "stepsDetailView.chart"
    /// Where the steps come from: Apple Health or the demo.
    static let source = "stepsDetailView.source"
}
