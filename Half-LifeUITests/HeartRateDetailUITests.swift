//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests HeartRateDetailUITests
//

import XCTest

/// The Insights tab's resting heart rate screen (UI-RHR-1 to UI-RHR-3 in the Insights article).
final class HeartRateDetailUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches past onboarding holding `healthData`, opens the Insights tab, and opens the resting heart rate screen.
    @MainActor
    private func openRestingHeartRate(
        withHealthData healthData: [String] = [LaunchEnvironmentKey.healthHeartRate]
    ) throws -> HeartRateDetailRobot {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: healthData)
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openInsights()
        try app.resolve(InsightsRobot.self).openHealthData(.restingHeartRate)
        return try app.resolve(HeartRateDetailRobot.self)
    }

    /// UI-RHR-1: the resting heart rate button opens the screen. With the empty drink log UI tests start with, no day
    /// follows a caffeine night, so there aren't enough days yet, and the heart rate comes from Apple Health.
    @MainActor
    func testTheButtonOpensTheScreenWithNotEnoughDaysYet() throws {
        let screen = try openRestingHeartRate()

        screen.verifyTitle()
        screen.verifyNotEnoughDaysYet()
        screen.verifySource(isDemo: false)
    }

    /// UI-RHR-2: the screen passes the accessibility audit.
    @MainActor
    func testTheScreenPassesTheAccessibilityAudit() throws {
        let screen = try openRestingHeartRate()

        try screen.auditAccessibilityAboveTheTabBar()
    }

    /// UI-RHR-3: with the demo drinks and the demo Health data, the screen compares the two groups of days, and says
    /// the data is the demo's.
    @MainActor
    func testWithTheDemoDataTheScreenComparesTheDays() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [])
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(SettingsRobot.self).open(.demoData)
        let demo = try app.resolve(DemoHistorySettingsRobot.self)
        demo.addDemoDrinks()
        demo.verifyHasDemoDrinks(true)
        demo.turnDemoHealthData(on: true)
        try app.resolve(AppRobot.self).openInsights()
        try app.resolve(InsightsRobot.self).openHealthData(.restingHeartRate)
        let screen = try app.resolve(HeartRateDetailRobot.self)

        screen.verifyShowsTheComparison()
        screen.verifySource(isDemo: true)
    }
}
