//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests StepsDetailUITests
//

import XCTest

/// The Insights tab's steps screen (UI-STEPS-1 to UI-STEPS-4 in the Insights article).
///
/// Each test starts with an empty drink log, and simulated Apple Health with 8,420 steps every day.
final class StepsDetailUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches past onboarding with steps in Apple Health, opens the Insights tab, and taps the steps button.
    @MainActor
    private func openSteps() throws -> StepsDetailRobot {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [LaunchEnvironmentKey.healthSteps])
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openInsights()
        try app.resolve(InsightsRobot.self).openHealthData(.steps)
        return try app.resolve(StepsDetailRobot.self)
    }

    /// UI-STEPS-1: tapping the steps button opens the steps screen.
    @MainActor
    func testTappingStepsOpensTheStepsScreen() throws {
        let steps = try openSteps()

        steps.verifyIsSteps()
        steps.verifyHasTheDaysChart()
    }

    /// UI-STEPS-2: with no caffeine nights, there are too few days to compare, and the other days average 8,420 steps
    /// over the 30 days.
    @MainActor
    func testWithNoCaffeineNightsThereAreTooFewDaysToCompare() throws {
        let steps = try openSteps()

        steps.verifyTooFewDaysToCompare()
        steps.verifyNoDaysAfterACaffeineNight()
        steps.verifyOtherDays(averaging: "8,420", over: 30)
    }

    /// UI-STEPS-4: the screen says what a caffeine night is, in words rather than an amount.
    @MainActor
    func testTheScreenSaysWhatACaffeineNightIs() throws {
        try openSteps().verifyDefinesACaffeineNight()
    }

    /// UI-STEPS-3: the steps screen passes the accessibility audit (constitution Article VI.4).
    @MainActor
    func testTheStepsScreenPassesTheAccessibilityAudit() throws {
        try openSteps().auditAccessibilityAboveTheTabBar()
    }
}
