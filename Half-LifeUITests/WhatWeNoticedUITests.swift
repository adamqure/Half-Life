//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests WhatWeNoticedUITests
//

import XCTest

/// The Insights tab's first card, "What we noticed" (UI-INS-13 to UI-INS-17 in the Insights article).
///
/// Each test turns on the demo drinks and the demo Health data in Settings, whose 30 days give the card its nights,
/// and chooses the language model with the launch environment, because a UI test can't rely on the Mac's.
final class WhatWeNoticedUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches past onboarding, with the simulated language model when `simulatedModel`, turns on the demo drinks
    /// and the demo Health data, and opens the Insights tab.
    @MainActor
    private func launchWithTheDemo(simulatedModel: Bool = true) throws -> InsightsRobot {
        let app = XCUIApplication()
        if simulatedModel {
            app.launchEnvironment[LaunchEnvironmentKey.languageModel] = LaunchEnvironmentKey.simulatedLanguageModel
        }
        app.launchPastOnboarding()
        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(SettingsRobot.self).open(.demoData)
        let demo = try app.resolve(DemoHistorySettingsRobot.self)
        demo.addDemoDrinks()
        demo.turnDemoHealthData(on: true)
        try app.resolve(AppRobot.self).openInsights()
        return try app.resolve(InsightsRobot.self)
    }

    /// UI-INS-13: with the simulated model and the demo's nights, the card shows a finding in the model's words, says
    /// it comes from the demo Health data, and asks "Feel right?".
    @MainActor
    func testWithTheDemoTheCardShowsAFindingAndAsks() throws {
        let insights = try launchWithTheDemo()

        insights.verifyNoticedCardAsks()
        insights.verifyNoticedCardSaysDemo()
    }

    /// UI-INS-14: "Yes" keeps the finding, without the question.
    @MainActor
    func testYesKeepsTheFindingWithoutTheQuestion() throws {
        let insights = try launchWithTheDemo()
        insights.verifyNoticedCardAsks()

        insights.answerFeelRight(.yes)

        insights.verifyNoticedCardWithoutTheQuestion()
    }

    /// UI-INS-15: "Not really" hides the card.
    @MainActor
    func testNotReallyHidesTheCard() throws {
        let insights = try launchWithTheDemo()
        insights.verifyNoticedCardAsks()

        insights.answerFeelRight(.notReally)

        insights.verifyNoNoticedCard()
    }

    /// UI-INS-16: without the language model, there's no card, even with the demo's nights.
    @MainActor
    func testWithoutTheModelThereIsNoCard() throws {
        try launchWithTheDemo(simulatedModel: false).verifyNoNoticedCard()
    }

    /// UI-INS-17: the tab passes the accessibility audit with the card showing.
    @MainActor
    func testTheTabWithTheCardPassesTheAccessibilityAudit() throws {
        let insights = try launchWithTheDemo()
        insights.verifyNoticedCardAsks()

        try insights.auditAccessibilityAboveTheTabBar()
    }
}
