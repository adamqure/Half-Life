//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests TodayRobot+History
//

import XCTest

/// Drives the Today screen's history card. It's part of `TodayRobot`, because the card is part of the Today screen.
/// The elements stay private to the robot (constitution Article II.8).
extension TodayRobot {
    /// A day the history card can show, by how its title names it.
    enum HistoryDay {
        case today, yesterday

        fileprivate var titleWord: String {
            switch self {
            case .today: "today"
            case .yesterday: "yesterday"
            }
        }
    }

    private var historyTitle: XCUIElement {
        app.descendants(matching: .any)[DrinkLogHistoryViewAccessibilityID.title]
    }

    private var previousDayButton: XCUIElement { app.buttons[DrinkLogHistoryViewAccessibilityID.previousDayButton] }
    private var nextDayButton: XCUIElement { app.buttons[DrinkLogHistoryViewAccessibilityID.nextDayButton] }
    private var todayButton: XCUIElement { app.buttons[DrinkLogHistoryViewAccessibilityID.todayButton] }
    private var confirmDeleteButton: XCUIElement { app.buttons[DrinkLogHistoryViewAccessibilityID.confirmDeleteButton] }
    private var cancelDeleteButton: XCUIElement { app.buttons[DrinkLogHistoryViewAccessibilityID.cancelDeleteButton] }

    private var loggedDrinks: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: DrinkLogHistoryViewAccessibilityID.drink)
    }

    private var deleteButtons: XCUIElementQuery {
        app.buttons.matching(identifier: DrinkLogHistoryViewAccessibilityID.deleteButton)
    }

    private var historyTotal: XCUIElement {
        app.descendants(matching: .any)[DrinkLogHistoryViewAccessibilityID.total]
    }

    /// The root screen's log button, which sits above the tab bar. Only its frame is read, to tell where the bar
    /// starts.
    private var logButton: XCUIElement { app.buttons[AppViewAccessibilityID.logButton] }

    /// Scrolls to the end of the Today screen, where the whole history card, down to its total, sits above the log
    /// button and the tab bar.
    ///
    /// It scrolls until the card stops moving, not just until its total clears the log button: text just above the
    /// button still fails the audit's contrast check.
    func showHistory(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            historyTotal.waitForExistence(timeout: 5), "The history card isn't there.", file: file, line: line)
        var previousFrame = CGRect.null
        var swipes = 0
        while historyTotal.frame != previousFrame && swipes < 8 {
            previousFrame = historyTotal.frame
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(
            isAboveTheBar(historyTotal), "The history card never came fully above the tab bar.", file: file,
            line: line)
    }

    /// Shows the day before.
    func showPreviousDay(file: StaticString = #filePath, line: UInt = #line) {
        tapHistoryButton(previousDayButton, named: "The previous day button", file: file, line: line)
    }

    /// Shows the day after.
    func showNextDay(file: StaticString = #filePath, line: UInt = #line) {
        tapHistoryButton(nextDayButton, named: "The next day button", file: file, line: line)
    }

    /// Returns the card to today.
    func jumpToToday(file: StaticString = #filePath, line: UInt = #line) {
        tapHistoryButton(todayButton, named: "The today button", file: file, line: line)
    }

    /// Asks to delete one of the listed drinks, without confirming.
    func startDeletingADrink(file: StaticString = #filePath, line: UInt = #line) {
        tapHistoryButton(deleteButtons.firstMatch, named: "A drink's delete button", file: file, line: line)
    }

    /// Keeps the drink waiting to be deleted.
    func keepTheDrink(file: StaticString = #filePath, line: UInt = #line) {
        tapHistoryButton(cancelDeleteButton, named: "The keep button", file: file, line: line)
    }

    /// Deletes one of the listed drinks, confirming when asked.
    func deleteADrink(file: StaticString = #filePath, line: UInt = #line) {
        startDeletingADrink(file: file, line: line)
        tapHistoryButton(confirmDeleteButton, named: "The confirm button", file: file, line: line)
    }

    /// How many drinks the card lists for its day, for a later `verifyLoggedDrinkCount(_:)`.
    func loggedDrinkCount() -> Int {
        _ = loggedDrinks.firstMatch.waitForExistence(timeout: 5)
        return loggedDrinks.count
    }

    /// Checks that the card lists `count` drinks, waiting for a deletion to arrive.
    func verifyLoggedDrinkCount(_ count: Int, file: StaticString = #filePath, line: UInt = #line) {
        let listed = NSPredicate { _, _ in loggedDrinks.count == count }
        let arrived = XCTNSPredicateExpectation(predicate: listed, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [arrived], timeout: 5), .completed,
            "The card lists \(loggedDrinks.count) drinks, not \(count).", file: file, line: line)
    }

    /// Checks that the card lists at least one drink.
    func verifyListsADrink(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            loggedDrinks.firstMatch.waitForExistence(timeout: 5), "The card lists no drinks.", file: file, line: line)
    }

    /// Checks that the card lists at least one demo drink, labeled as one.
    func verifyListsADemoDrink(file: StaticString = #filePath, line: UInt = #line) {
        let labeled = NSPredicate { _, _ in
            loggedDrinks.allElementsBoundByIndex.contains { $0.label.contains("Demo") }
        }
        let arrived = XCTNSPredicateExpectation(predicate: labeled, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [arrived], timeout: 5), .completed, "The card lists no drink labeled Demo.", file: file,
            line: line)
    }

    /// Checks that the card is asking whether to delete a drink.
    func verifyDeletionIsAsked(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            confirmDeleteButton.waitForExistence(timeout: 5), "The card isn't asking to confirm.", file: file,
            line: line)
        XCTAssertTrue(cancelDeleteButton.exists, "The card offers no way to keep the drink.", file: file, line: line)
    }

    /// Checks that the card's title names `day`.
    func verifyHistoryShows(_ day: HistoryDay, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            historyTitle.waitForExistence(timeout: 5), "The history card isn't there.", file: file, line: line)
        let titled = NSPredicate { _, _ in historyTitle.label.lowercased().contains(day.titleWord) }
        let arrived = XCTNSPredicateExpectation(predicate: titled, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [arrived], timeout: 5), .completed,
            "The card's title reads \"\(historyTitle.label)\", not \(day.titleWord).", file: file, line: line)
    }

    /// Checks whether the card offers the next day. It never goes past today.
    func verifyCanShowNextDay(_ canShow: Bool, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            nextDayButton.waitForExistence(timeout: 5), "The next day button isn't there.", file: file, line: line)
        XCTAssertEqual(nextDayButton.isEnabled, canShow, file: file, line: line)
    }

    /// Checks whether the card offers a way back to today. It does only on an earlier day.
    func verifyCanJumpToToday(_ canJump: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let offered = NSPredicate { _, _ in todayButton.exists == canJump }
        let settled = XCTNSPredicateExpectation(predicate: offered, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [settled], timeout: 5), .completed,
            canJump ? "The card offers no way back to today." : "The card offers today while showing today.",
            file: file, line: line)
    }

    /// Where the card's title is on screen, for a later `verifyHistoryTitleTop(is:)`.
    func historyTitleTop(file: StaticString = #filePath, line: UInt = #line) -> CGFloat {
        XCTAssertTrue(
            historyTitle.waitForExistence(timeout: 5), "The history card isn't there.", file: file, line: line)
        return historyTitle.frame.minY
    }

    /// Checks that the card's title is still at `top` on screen, give or take a point, so changing the day didn't
    /// scroll the Today screen.
    func verifyHistoryTitleTop(is top: CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            historyTitle.waitForExistence(timeout: 5), "The history card isn't there.", file: file, line: line)
        XCTAssertEqual(
            historyTitle.frame.minY, top, accuracy: 1, "Changing the day moved the history card on screen.",
            file: file, line: line)
    }

    /// Whether all of `element` is above the log button, and so above the tab bar.
    private func isAboveTheBar(_ element: XCUIElement) -> Bool {
        element.exists && !element.frame.isEmpty && element.frame.maxY <= logButton.frame.minY
    }

    private func tapHistoryButton(_ button: XCUIElement, named name: String, file: StaticString, line: UInt) {
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(name) isn't showing.", file: file, line: line)
        button.tap()
    }
}
