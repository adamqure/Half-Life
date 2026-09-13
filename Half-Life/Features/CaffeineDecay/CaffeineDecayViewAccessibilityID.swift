//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineDecayViewAccessibilityID
//

/// Accessibility identifiers for ``CaffeineDecayView`` (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and `TodayRobot` share
/// one definition.
enum CaffeineDecayViewAccessibilityID {
    /// The caffeine in your system now.
    static let level = "caffeineDecayView.level"
    /// The decay curve.
    static let curve = "caffeineDecayView.curve"
    /// The times at the curve's two ends.
    static let timeSpan = "caffeineDecayView.timeSpan"
}
