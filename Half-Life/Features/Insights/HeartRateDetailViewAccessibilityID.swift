//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HeartRateDetailViewAccessibilityID
//

/// Accessibility identifiers for ``HeartRateDetailView`` (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and
/// `HeartRateDetailRobot` share one definition.
enum HeartRateDetailViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "heartRateDetailView.screen"
    /// The screen's title, "Resting heart rate".
    static let title = "heartRateDetailView.title"
    /// What the days show: the difference, no clear difference, or not enough days yet.
    static let headline = "heartRateDetailView.headline"
    /// The sentence under the headline.
    static let headlineDetail = "heartRateDetailView.headlineDetail"
    /// The average and day count after a caffeine night.
    static let afterCaffeine = "heartRateDetailView.afterCaffeine"
    /// The average and day count after the other nights.
    static let otherDays = "heartRateDetailView.otherDays"
    /// The chart of each day's resting heart rate.
    static let chart = "heartRateDetailView.chart"
    /// The note on what the comparison can and can't say.
    static let footnote = "heartRateDetailView.footnote"
    /// Where the heart rate and sleep come from: Apple Health, or the demo.
    static let source = "heartRateDetailView.source"
}
