//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHistorySettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' Demo data screen, shared with the UI test target.
enum DemoHistorySettingsViewAccessibilityID {
    /// The screen's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "demoHistorySettingsView.screen"
    /// The button that adds the demo drinks, shown while the log holds none.
    static let addDemoButton = "demoHistorySettingsView.addDemoButton"
    /// The button that removes the demo drinks, shown while the log holds some.
    static let removeDemoButton = "demoHistorySettingsView.removeDemoButton"
    /// The message that the last add or removal of the demo drinks failed.
    static let demoError = "demoHistorySettingsView.demoError"
    /// The option that shows demo Health data on the Today screen in place of Apple Health's.
    static let demoHealthDataOption = "demoHistorySettingsView.demoHealthDataOption"
    /// The message that the last change to the demo Health data switch failed.
    static let demoHealthDataError = "demoHistorySettingsView.demoHealthDataError"
}
