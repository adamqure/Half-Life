//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests InsightsUITests
//

import XCTest

/// The Insights tab (UI-INS-1 to UI-INS-12 in the Insights article).
final class InsightsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches past onboarding, and opens the Insights tab.
    @MainActor
    private func launchIntoInsights() throws -> (XCUIApplication, InsightsRobot) {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openInsights()
        return (app, try app.resolve(InsightsRobot.self))
    }

    /// UI-INS-1: Insights opens from its tab, and Today opens again from its own.
    @MainActor
    func testInsightsOpensFromItsTabAndTodayFromItsOwn() throws {
        let (app, _) = try launchIntoInsights()

        try app.resolve(AppRobot.self).openToday()
        try app.resolve(TodayRobot.self).verifyGreetingForTheTimeOfDay()
    }

    /// UI-INS-2: with the empty drink log each UI test starts with, tonight's window runs from the profile's 10:30 PM
    /// bedtime to midnight, shown as clock times with no date, because caffeine is under the threshold by then.
    @MainActor
    func testWithNothingLoggedTonightsWindowStartsAtBedtime() throws {
        let (_, insights) = try launchIntoInsights()

        insights.verifySleepWindowStartsAtBedtime("10:30", until: "12:00")
    }

    /// UI-INS-18: until the user's nights show a trend, as in a UI test that doesn't turn the demo on, the sleep
    /// window's footnote says its threshold is one clinical sleep studies support for the average person.
    @MainActor
    func testWithoutATrendTheFootnoteNamesSleepStudies() throws {
        let (_, insights) = try launchIntoInsights()

        insights.verifySleepWindowThreshold(isLearned: false)
    }

    /// UI-INS-19: with the demo's nights, which show a trend, the footnote says the threshold comes from the user's
    /// time asleep.
    @MainActor
    func testWithTheDemosTrendTheFootnoteNamesYourTimeAsleep() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(SettingsRobot.self).open(.demoData)
        let demo = try app.resolve(DemoHistorySettingsRobot.self)
        demo.addDemoDrinks()
        demo.turnDemoHealthData(on: true)
        try app.resolve(AppRobot.self).openInsights()

        try app.resolve(InsightsRobot.self).verifySleepWindowThreshold(isLearned: true)
    }

    /// UI-INS-3: the Insights tab passes the system accessibility audit (constitution Article VI.4).
    @MainActor
    func testInsightsPassesTheAccessibilityAudit() throws {
        let (_, insights) = try launchIntoInsights()

        try insights.auditAccessibilityAboveTheTabBar()
    }

    /// UI-INS-4: with the empty drink log each UI test starts with, the last 7 days card has a column for each of the
    /// 7 days before today, and yesterday is selected, with no caffeine and no last cup.
    @MainActor
    func testWithNothingLoggedTheWeekSelectsYesterdayWithNoCaffeine() throws {
        let (_, insights) = try launchIntoInsights()

        insights.verifyWeekHasSevenDays()
        insights.verifySelectedDay("Yesterday", caffeine: "0 mg")
        insights.verifyHasLastCup(false)
        insights.verifyWeekHasNoSleep()
    }

    /// UI-INS-5: a drink logged today isn't in the week, which ends yesterday, because today has no sleep yet.
    @MainActor
    func testADrinkLoggedTodayIsntInTheWeek() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openDrinkComposer()
        let composer = try app.resolve(DrinkComposerRobot.self)
        composer.selectDrink(.espresso)
        composer.logDrink()
        composer.verifyClosed()

        try app.resolve(AppRobot.self).openInsights()
        let insights = try app.resolve(InsightsRobot.self)

        insights.verifySelectedDay("Yesterday", caffeine: "0 mg")
        insights.verifyHasLastCup(false)
    }

    /// UI-INS-20: with the demo drinks, yesterday, the day selected, has a last cup.
    @MainActor
    func testTheDemosDrinksShowInTheWeek() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(SettingsRobot.self).open(.demoData)
        try app.resolve(DemoHistorySettingsRobot.self).addDemoDrinks()
        try app.resolve(AppRobot.self).openInsights()

        try app.resolve(InsightsRobot.self).verifyHasLastCup(true)
    }

    /// UI-INS-6: choosing the column for 2 days ago shows that day's details, named by its weekday.
    @MainActor
    func testChoosingADayShowsIt() throws {
        let (_, insights) = try launchIntoInsights()
        let twoDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: .now))
        // The UI tests run the app in English (constitution Article II.6).
        let weekday = twoDaysAgo.formatted(Date.FormatStyle(locale: Locale(identifier: "en_US")).weekday(.wide))

        insights.chooseDay(daysAgo: 2)

        insights.verifySelectedDay(weekday, caffeine: "0 mg")
    }

    /// UI-INS-7: with last night's sleep in Apple Health, yesterday, the day selected, shows last night: 7 hours
    /// asleep, from 11pm to 6am.
    @MainActor
    func testWithSleepInHealthYesterdaysNightIsLastNight() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [LaunchEnvironmentKey.healthSleep])
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openInsights()
        let insights = try app.resolve(InsightsRobot.self)

        insights.verifySelectedDay("Yesterday", caffeine: "0 mg")
        insights.verifySelectedDaySlept("7h")
    }

    /// UI-INS-8: with last night's sleep in Apple Health, the Insights tab passes the accessibility audit.
    @MainActor
    func testWithSleepInHealthInsightsPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: [LaunchEnvironmentKey.healthSleep])
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openInsights()

        try app.resolve(InsightsRobot.self).auditAccessibilityAboveTheTabBar()
    }

    /// Launches past onboarding holding `healthData`, and opens the Insights tab.
    @MainActor
    private func launchIntoInsights(withHealthData healthData: [String]) throws -> (XCUIApplication, InsightsRobot) {
        let app = XCUIApplication()
        app.launchPastOnboarding(withHealthData: healthData)
        _ = try app.resolve(TodayRobot.self)
        try app.resolve(AppRobot.self).openInsights()
        return (app, try app.resolve(InsightsRobot.self))
    }

    /// UI-INS-9: with no Health data, there's no Health data card.
    @MainActor
    func testWithNoHealthDataThereIsNoHealthDataCard() throws {
        let (_, insights) = try launchIntoInsights(withHealthData: [])

        insights.verifyNoHealthDataCard()
    }

    /// UI-INS-10: each kind of Health data that has data has a button: sleep, steps, and resting heart rate.
    @MainActor
    func testEachKindWithDataHasAButton() throws {
        let (_, insights) = try launchIntoInsights(withHealthData: [
            LaunchEnvironmentKey.healthSleep, LaunchEnvironmentKey.healthSteps, LaunchEnvironmentKey.healthHeartRate,
        ])

        insights.verifyHealthDataButtons([.sleep, .steps, .restingHeartRate])
    }

    /// UI-INS-10: with only steps, only steps has a button.
    @MainActor
    func testWithOnlyStepsOnlyStepsHasAButton() throws {
        let (_, insights) = try launchIntoInsights(withHealthData: [LaunchEnvironmentKey.healthSteps])

        insights.verifyHealthDataButtons([.steps])
    }

    /// UI-INS-11: tapping the sleep button opens the Sleep screen. With last night's sleep and the empty drink log UI
    /// tests start with, no night counts yet, so it has too few nights to say, no chart, and no time in bed to compare.
    @MainActor
    func testTappingSleepOpensTheSleepScreen() throws {
        let (app, insights) = try launchIntoInsights(withHealthData: [LaunchEnvironmentKey.healthSleep])

        insights.openHealthData(.sleep)

        let sleep = try app.resolve(SleepDetailRobot.self)
        sleep.verifyTitle("Sleep")
        sleep.verifyFinding(startingWith: "Not enough nights to say yet")
        sleep.verifyNoNightsCharted()
        sleep.verifyFallingAsleepNoteAndSource("Sleep from Apple Health")
    }

    /// UI-INS-12: the Sleep screen passes the accessibility audit.
    @MainActor
    func testTheSleepScreenPassesTheAccessibilityAudit() throws {
        let (app, insights) = try launchIntoInsights(withHealthData: [LaunchEnvironmentKey.healthSleep])
        insights.openHealthData(.sleep)

        try app.resolve(SleepDetailRobot.self).auditAccessibilityAboveTheTabBar()
    }
}
