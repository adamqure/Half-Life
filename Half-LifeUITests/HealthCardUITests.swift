//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests HealthCardUITests
//

import XCTest

/// The Today screen's Apple Health card (HUI-1 to HUI-6 in the Apple Health Card article).
///
/// Each test chooses the Health data the app holds with the launch environment's Health data key, because a UI test
/// can't grant Health access or add Health data.
final class HealthCardUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// HUI-1: with no Health data, the Today screen has no Apple Health card.
    @MainActor
    func testWithNoHealthDataTheCardIsHidden() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [])

        let today = try app.resolve(TodayRobot.self)
        today.verifyHealthCardIsHidden()
    }

    /// HUI-2: with only steps and resting heart rate, the card shows those two, and no sleep.
    @MainActor
    func testWithStepsAndHeartRateTheCardShowsOnlyThose() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [
            LaunchEnvironmentKey.healthSteps, LaunchEnvironmentKey.healthHeartRate,
        ])

        let today = try app.resolve(TodayRobot.self)
        today.showHealthCard()
        today.verifyHealthCard(shows: [.steps, .restingHeartRate])
    }

    /// HUI-3: with sleep, steps, and resting heart rate, the card shows all three.
    @MainActor
    func testWithEveryMetricTheCardShowsAllThree() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [
            LaunchEnvironmentKey.healthSleep, LaunchEnvironmentKey.healthSteps, LaunchEnvironmentKey.healthHeartRate,
        ])

        let today = try app.resolve(TodayRobot.self)
        today.showHealthCard()
        today.verifyHealthCard(shows: [.lastNight, .steps, .restingHeartRate])
    }

    /// HUI-4: with time in bed and no sleep, the card shows the time in bed, and says it isn't sleep.
    @MainActor
    func testWithOnlyTimeInBedTheCardSaysItIsNotSleep() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [LaunchEnvironmentKey.healthInBed])

        let today = try app.resolve(TodayRobot.self)
        today.showHealthCard()
        today.verifyHealthCard(shows: [.inBed])
        today.verifyTimeInBedSaysItIsNotSleep()
    }

    /// HUI-5: turning on the demo Health data in Settings shows the card, under "Demo Health data", with the demo's
    /// last night. Turning it off hides the card again, because the simulated Health holds nothing.
    @MainActor
    func testTheDemoSwitchShowsTheDemoCardAndHidesItAgain() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [])
        try app.resolve(TodayRobot.self).verifyHealthCardIsHidden()

        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(SettingsRobot.self).open(.demoData)
        try app.resolve(DemoHistorySettingsRobot.self).turnDemoHealthData(on: true)
        try app.resolve(AppRobot.self).openToday()
        let today = try app.resolve(TodayRobot.self)
        today.showHealthCard()
        today.verifyHealthCardShowsDemoData()

        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(DemoHistorySettingsRobot.self).turnDemoHealthData(on: false)
        try app.resolve(AppRobot.self).openToday()
        try app.resolve(TodayRobot.self).verifyHealthCardIsHidden()
    }

    /// HUI-6: the Today screen passes the accessibility audit with the card showing, as UI-2 does without it.
    @MainActor
    func testTheTodayScreenWithTheCardPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [
            LaunchEnvironmentKey.healthSleep, LaunchEnvironmentKey.healthSteps, LaunchEnvironmentKey.healthHeartRate,
        ])

        let today = try app.resolve(TodayRobot.self)
        today.verifyHealthCard(shows: [.lastNight, .steps, .restingHeartRate])
        try today.auditAccessibilityAboveTheTabBar()
    }

    /// HUI-7: scrolled to its end, the Today screen shows the whole card, clear of the log button and the tab bar's
    /// fade above it.
    @MainActor
    func testScrolledToTheEndTheCardClearsTheLogButton() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [
            LaunchEnvironmentKey.healthSleep, LaunchEnvironmentKey.healthSteps, LaunchEnvironmentKey.healthHeartRate,
        ])

        let today = try app.resolve(TodayRobot.self)
        today.showHealthCard()
        today.verifyHealthCardClearsTheLogButton()
    }
}

@MainActor
extension XCUIApplication {
    /// Launches the app past onboarding, holding the Health data `data` names, from ``LaunchEnvironmentKey``'s Health
    /// data values. With none, the app holds no Health data.
    func launchPastOnboarding(withHealthData data: [String]) {
        launchEnvironment[LaunchEnvironmentKey.healthData] = data.joined(separator: ",")
        launchPastOnboarding()
    }
}
