//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BedtimeSettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' Bedtime screen, shared with the UI test target.
enum BedtimeSettingsViewAccessibilityID {
    /// The screen's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "bedtimeSettingsView.screen"
    /// The bedtime's time picker.
    static let picker = "bedtimeSettingsView.picker"
}
