//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FactorsSettingsViewAccessibilityID
//

/// Accessibility identifiers for Settings' Caffeine and your body screen, shared with the UI test target.
enum FactorsSettingsViewAccessibilityID {
    /// The screen's element, its scroll view, which robots use to detect the screen and to scroll it.
    static let screen = "factorsSettingsView.screen"
    /// The option for a pregnancy.
    static let pregnantOption = "factorsSettingsView.pregnantOption"
    /// The first trimester, shown while the pregnancy option is chosen.
    static let firstTrimester = "factorsSettingsView.firstTrimester"
    /// The second trimester.
    static let secondTrimester = "factorsSettingsView.secondTrimester"
    /// The third trimester.
    static let thirdTrimester = "factorsSettingsView.thirdTrimester"
    /// The option for estrogen.
    static let estrogenOption = "factorsSettingsView.estrogenOption"
    /// The option for smoking.
    static let smokesOption = "factorsSettingsView.smokesOption"
    /// The option for cirrhosis.
    static let cirrhosisOption = "factorsSettingsView.cirrhosisOption"
    /// The option for fluvoxamine.
    static let fluvoxamineOption = "factorsSettingsView.fluvoxamineOption"
}
