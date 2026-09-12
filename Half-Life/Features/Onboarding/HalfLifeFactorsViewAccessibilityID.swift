//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeFactorsViewAccessibilityID
//

/// Accessibility identifiers for onboarding's step about what changes the half-life, shared with the UI test target.
enum HalfLifeFactorsViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "halfLifeFactorsView.screen"
    /// The step's scrolling content.
    static let content = "halfLifeFactorsView.content"
    /// The "None of these" option.
    static let noneOption = "halfLifeFactorsView.noneOption"
    /// The "I'm pregnant" option.
    static let pregnantOption = "halfLifeFactorsView.pregnantOption"
    /// The first trimester choice.
    static let firstTrimester = "halfLifeFactorsView.firstTrimester"
    /// The second trimester choice.
    static let secondTrimester = "halfLifeFactorsView.secondTrimester"
    /// The third trimester choice.
    static let thirdTrimester = "halfLifeFactorsView.thirdTrimester"
    /// The "I take estrogen" option.
    static let estrogenOption = "halfLifeFactorsView.estrogenOption"
    /// The "I smoke cigarettes" option.
    static let smokesOption = "halfLifeFactorsView.smokesOption"
    /// The "I have cirrhosis of the liver" option.
    static let cirrhosisOption = "halfLifeFactorsView.cirrhosisOption"
    /// The "I take fluvoxamine" option.
    static let fluvoxamineOption = "halfLifeFactorsView.fluvoxamineOption"
    /// The starting half-life the choices give.
    static let halfLife = "halfLifeFactorsView.halfLife"
    /// The button that moves on.
    static let continueButton = "halfLifeFactorsView.continueButton"
}
