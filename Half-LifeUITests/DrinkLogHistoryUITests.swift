//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests DrinkLogHistoryUITests
//

import XCTest

/// The Today screen's history card (UI-6 to UI-9 in the Today Screen article).
///
/// Every launch starts with an empty drink log (LAUNCH-3 in the Onboarding article), so a scenario that needs a drink
/// logs one through the composer first.
final class DrinkLogHistoryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app, logs a drink now through the composer, and scrolls to the history card.
    @MainActor
    private func launchWithADrinkLoggedToday(_ app: XCUIApplication) throws -> TodayRobot {
        app.launchPastOnboarding()
        try app.resolve(AppRobot.self).openDrinkComposer()
        try app.resolve(DrinkComposerRobot.self).logDrink()
        let today = try app.resolve(TodayRobot.self)
        today.showHistory()
        return today
    }

    /// UI-6: the history card opens on today, and lists the drink just logged.
    @MainActor
    func testHistoryShowsTodaysDrinks() throws {
        let today = try launchWithADrinkLoggedToday(XCUIApplication())

        today.verifyHistoryShows(.today)
        today.verifyListsADrink()
    }

    /// UI-7: deleting a drink asks first. Keeping it leaves the list alone, and confirming removes it.
    @MainActor
    func testDeletingADrinkAsksFirstThenRemovesIt() throws {
        let today = try launchWithADrinkLoggedToday(XCUIApplication())
        let count = today.loggedDrinkCount()

        today.startDeletingADrink()
        today.verifyDeletionIsAsked()
        today.keepTheDrink()
        today.verifyLoggedDrinkCount(count)

        today.deleteADrink()
        today.verifyLoggedDrinkCount(count - 1)
    }

    /// UI-8: the buttons move to yesterday and back, and never past today.
    @MainActor
    func testMovingBetweenDays() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        let today = try app.resolve(TodayRobot.self)
        today.showHistory()
        today.verifyHistoryShows(.today)
        today.verifyCanShowNextDay(false)

        today.showPreviousDay()
        today.verifyHistoryShows(.yesterday)
        today.verifyCanShowNextDay(true)

        today.showNextDay()
        today.verifyHistoryShows(.today)
    }

    /// UI-9: the history card passes the system accessibility audit, with and without a deletion waiting
    /// (constitution Article VI.4).
    ///
    /// The Today screen is in the root tab bar, so it audits with `auditAccessibilityAboveTheTabBar()`, the exception
    /// the owner approved for every screen there (see the Architecture article). `showHistory()` has already brought
    /// the whole card above the bar, so all of the card's text is checked.
    @MainActor
    func testHistoryPassesAccessibilityAudit() throws {
        let today = try launchWithADrinkLoggedToday(XCUIApplication())
        try today.auditAccessibilityAboveTheTabBar()

        today.startDeletingADrink()
        today.verifyDeletionIsAsked()
        // Keep and Delete make the row taller, which pushes the card's end back under the bar.
        today.showHistory()
        try today.auditAccessibilityAboveTheTabBar()
        today.keepTheDrink()
    }

    /// UI-10: Today returns the card to today from an earlier day, and shows only on an earlier day.
    @MainActor
    func testTodayReturnsTheCardToToday() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        let today = try app.resolve(TodayRobot.self)
        today.showHistory()
        today.verifyCanJumpToToday(false)

        today.showPreviousDay()
        today.showPreviousDay()
        today.verifyCanJumpToToday(true)
        today.jumpToToday()

        today.verifyHistoryShows(.today)
        today.verifyCanJumpToToday(false)
    }

    /// UI-11: changing the day leaves the card where it was on screen. The Today screen doesn't scroll away from it.
    @MainActor
    func testChangingTheDayKeepsTheCardInPlace() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        let today = try app.resolve(TodayRobot.self)
        today.showHistory()
        let top = today.historyTitleTop()

        today.showPreviousDay()
        today.verifyHistoryShows(.yesterday)
        today.verifyHistoryTitleTop(is: top)

        today.showNextDay()
        today.verifyHistoryShows(.today)
        today.verifyHistoryTitleTop(is: top)
    }
}
