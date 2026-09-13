//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepDetailViewAccessibilityID
//

/// Accessibility identifiers for ``SleepDetailView`` (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and `SleepDetailRobot` share
/// one definition.
enum SleepDetailViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "sleepDetailView.screen"
    /// The screen's title, "Sleep".
    static let title = "sleepDetailView.title"
    /// The analysis card, above both charts: what the nights show.
    static let analysisCard = "sleepDetailView.analysisCard"
    /// The time asleep card.
    static let timeAsleepCard = "sleepDetailView.timeAsleepCard"
    /// What the nights show across both charts: the tolerance, no drop, or too few nights, and the time to fall asleep.
    static let finding = "sleepDetailView.finding"
    /// The chart of each night's time asleep against its caffeine at sleep onset.
    static let timeAsleepChart = "sleepDetailView.timeAsleepChart"
    /// The average time asleep either side of the threshold.
    static let timeAsleepComparison = "sleepDetailView.timeAsleepComparison"
    /// The time to fall asleep card.
    static let fallingAsleepCard = "sleepDetailView.fallingAsleepCard"
    /// Why the time to fall asleep can't be compared yet, when it can't.
    static let fallingAsleepNote = "sleepDetailView.fallingAsleepNote"
    /// The chart of each night's time to fall asleep against its caffeine at sleep onset.
    static let fallingAsleepChart = "sleepDetailView.fallingAsleepChart"
    /// The average time to fall asleep either side of the threshold.
    static let fallingAsleepComparison = "sleepDetailView.fallingAsleepComparison"
    /// Where the sleep comes from: Apple Health or the demo.
    static let source = "sleepDetailView.source"
}
