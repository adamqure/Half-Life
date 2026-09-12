//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests TodayUITests
//

import XCTest

/// The Today screen (UI-1 to UI-5 in the Today Screen article, and UI-LASTCUP in the Caffeine Cutoff article).
final class TodayUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// UI-LASTCUP: the Today screen shows the cutoff for the usual drink.
    @MainActor
    func testTodayShowsTheLastCupForTheUsualDrink() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        let today = try app.resolve(TodayRobot.self)
        today.verifyLastCup()
    }

    /// UI-4: the Today screen shows the caffeine logged today, in milligrams.
    @MainActor
    func testTodayShowsTheCaffeineLoggedToday() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        let today = try app.resolve(TodayRobot.self)
        today.verifyCaffeineLoggedToday()
    }

    /// UI-5: logging a drink adds its caffeine to today's total. The app uses the simulator's own drink log, so the
    /// test compares the total before and after: one espresso shot adds 62.7 mg, about 63 once each total is rounded.
    /// It would fail if midnight passed between the two readings.
    @MainActor
    func testLoggingADrinkAddsItsCaffeineToToday() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        let before = try XCTUnwrap(try app.resolve(TodayRobot.self).caffeineLoggedToday())

        try app.resolve(AppRobot.self).openDrinkComposer()
        let composer = try app.resolve(DrinkComposerRobot.self)
        composer.selectDrink(.espresso)
        composer.verifyEstimate("63 mg")
        composer.logDrink()
        composer.verifyClosed()

        let today = try app.resolve(TodayRobot.self)
        today.verifyCaffeineLoggedToday(isAbout: before + 63)
    }

    /// ONETAP-UI-1: one tap on a favourite logs it. The button says so, and its caffeine is added to today's total.
    /// Each UI test starts with an empty drink log, so the first favourite is the first starter, 2 espresso shots.
    /// Logging it only adds to its count, so it stays first.
    @MainActor
    func testOneTapLogsAFavourite() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        let today = try app.resolve(TodayRobot.self)
        let before = try XCTUnwrap(today.caffeineLoggedToday())
        let added = try XCTUnwrap(today.caffeine(in: .first))

        today.logFavourite(.first)

        today.verifyFavouriteWasLogged(.first)
        today.verifyCaffeineLoggedToday(isAbout: before + added)
    }

    /// UI-3: the Today screen shows the caffeine in your system now, and its decay curve.
    @MainActor
    func testTodayShowsTheCaffeineInYourSystemNow() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        let today = try app.resolve(TodayRobot.self)
        today.verifyCaffeineInYourSystem()
    }

    /// UI-1: launching the app shows the Today screen, with a greeting for the time of day.
    @MainActor
    func testLaunchShowsAGreetingForTheTimeOfDay() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        let today = try app.resolve(TodayRobot.self)
        today.verifyGreetingForTheTimeOfDay()
    }

    /// UI-2: the Today screen passes the system accessibility audit (constitution Article VI.4).
    @MainActor
    func testTodayScreenPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        let today = try app.resolve(TodayRobot.self)
        today.verifyGreetingForTheTimeOfDay()
        today.verifyCaffeineInYourSystem()
        today.verifyCaffeineLoggedToday()
        today.verifyLastCup()
        // The owner approved this on 2026-09-12. At launch, contrast is ignored only for elements under the tab bar
        // or in its fade, and for issues with no element. Then the screen scrolls to its end, and the second audit
        // ignores nothing.
        // See auditAccessibilityAboveTheTabBar.
        try today.auditAccessibilityAboveTheTabBar()
    }
}
