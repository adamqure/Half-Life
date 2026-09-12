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

/// The Today screen (UI-1 to UI-3 in the Today Screen article).
final class TodayUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// UI-3: the Today screen shows the caffeine in your system now, and its decay curve.
    @MainActor
    func testTodayShowsTheCaffeineInYourSystemNow() throws {
        let app = XCUIApplication()
        app.launch()

        let today = try app.resolve(TodayRobot.self)
        today.verifyCaffeineInYourSystem()
    }

    /// UI-1: launching the app shows the Today screen, with a greeting for the time of day.
    @MainActor
    func testLaunchShowsAGreetingForTheTimeOfDay() throws {
        let app = XCUIApplication()
        app.launch()

        let today = try app.resolve(TodayRobot.self)
        today.verifyGreetingForTheTimeOfDay()
    }

    /// UI-2: the Today screen passes the system accessibility audit (constitution Article VI.4).
    @MainActor
    func testTodayScreenPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()

        let today = try app.resolve(TodayRobot.self)
        today.verifyGreetingForTheTimeOfDay()
        today.verifyCaffeineInYourSystem()
        try today.auditAccessibility()
    }
}
