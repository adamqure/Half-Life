//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthSummaryViewAccessibilityID
//

/// Accessibility identifiers for ``HealthSummaryView`` (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and `TodayRobot` share one
/// definition. The card is part of the Today screen, so it has no `screen` identifier.
enum HealthSummaryViewAccessibilityID {
    /// The eyebrow above the card: "From Apple Health", or "Demo Health data".
    static let title = "healthSummaryView.title"
    /// The card.
    static let card = "healthSummaryView.card"
    /// Last night's time asleep, which VoiceOver reads as one element.
    static let lastNight = "healthSummaryView.lastNight"
    /// Last night's time in bed, shown when no sleep was recorded.
    static let inBed = "healthSummaryView.inBed"
    /// Today's steps.
    static let steps = "healthSummaryView.steps"
    /// Today's resting heart rate.
    static let restingHeartRate = "healthSummaryView.restingHeartRate"
}
