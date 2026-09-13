//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests InsightsRobot
//

import XCTest

/// Drives `InsightsView`, the Insights tab: tonight's sleep window, the last 7 days, and the other cards as they're
/// built.
struct InsightsRobot: Robot {
    /// The Insights tab's identifier.
    static let screenIdentifier = InsightsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var times: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.sleepWindowTimes] }
    private var summary: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.sleepWindowSummary]
    }
    private var chart: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.sleepWindowChart] }
    private var content: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.content] }
    private var dayTitle: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.weekDetailTitle] }
    private var dayCaffeine: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.weekDetailCaffeine]
    }
    private var daySleep: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.weekDetailSleep]
    }
    private var sleepNote: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.weekSleepNote] }
    private var dayLastCup: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.weekDetailLastCup]
    }

    private var footnote: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.sleepWindowFootnote]
    }

    /// The last 7 days card's column for the day `daysAgo` days before today, from 1, yesterday, to 7.
    private func column(daysAgo: Int) -> XCUIElement {
        app.buttons[InsightsViewAccessibilityID.weekColumns[InsightsViewAccessibilityID.weekColumns.count - daysAgo]]
    }

    /// Checks that tonight's window runs from `start` to `end`, as they're shown, such as "10:30" and "12:00", with
    /// only clock times and no date, and that it says why it starts at the bedtime: caffeine should be under the
    /// threshold by then. That's the case with nothing logged, as each UI test starts.
    func verifySleepWindowStartsAtBedtime(
        _ start: String, until end: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        require(times, "Tonight's sleep window", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: times) { $0.contains(start) && $0.contains(end) && !$0.contains("/") },
            "The window reads \"\(times.label)\", not only the times \(start) to \(end).", file: file, line: line)
        require(summary, "The sleep window's summary", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: summary) { $0.lowercased().contains("by your") },
            "The summary reads \"\(summary.label)\", not that caffeine clears by bedtime.", file: file, line: line)
        require(chart, "The caffeine chart", file: file, line: line)
    }

    /// Checks that the sleep window's footnote says where its threshold comes from: the trend in the user's time
    /// asleep when `isLearned`, or clinical sleep studies until their nights show one. A learned threshold can take a
    /// while to reach the card, while the demo's nights are analyzed.
    func verifySleepWindowThreshold(isLearned: Bool, file: StaticString = #filePath, line: UInt = #line) {
        reveal(footnote, on: content, "The sleep window's footnote", file: file, line: line)
        let phrase = isLearned ? "your time asleep" : "clinical sleep studies"
        let says = NSPredicate { object, _ in ((object as? XCUIElement)?.label ?? "").contains(phrase) }
        let result = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: says, object: footnote)], timeout: 20)
        XCTAssertEqual(
            result, .completed, "The footnote reads \"\(footnote.label)\", not \"\(phrase)\".", file: file,
            line: line)
    }

    /// Chooses the day `daysAgo` days before today on the last 7 days card.
    func chooseDay(daysAgo: Int, file: StaticString = #filePath, line: UInt = #line) {
        let day = column(daysAgo: daysAgo)
        reveal(day, on: content, "The column for \(daysAgo) days ago", file: file, line: line)
        day.tap()
    }

    /// Checks that the last 7 days card has a column for each of the 7 days before today.
    func verifyWeekHasSevenDays(file: StaticString = #filePath, line: UInt = #line) {
        for daysAgo in 1...7 {
            reveal(column(daysAgo: daysAgo), on: content, "The column for \(daysAgo) days ago", file: file, line: line)
        }
    }

    /// Checks that the card's details are for `day`, as it's named, such as "Today" or "Yesterday", and show
    /// `caffeine`, such as "63 mg".
    func verifySelectedDay(
        _ day: String, caffeine: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        reveal(dayCaffeine, on: content, "The day's caffeine", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: dayTitle) { $0 == day }, "The details are for \"\(dayTitle.label)\", not \(day).",
            file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: dayCaffeine) { $0.contains(caffeine) },
            "The day's caffeine reads \"\(dayCaffeine.label)\", not \(caffeine).", file: file, line: line)
    }

    /// Checks whether the chosen day's details show a last cup, or "None".
    func verifyHasLastCup(_ hasLastCup: Bool, file: StaticString = #filePath, line: UInt = #line) {
        reveal(dayLastCup, on: content, "The day's last cup", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: dayLastCup) { $0.contains("None") != hasLastCup },
            "The last cup reads \"\(dayLastCup.label)\".", file: file, line: line)
    }

    /// Checks that the chosen day's details show its sleep as `sleep`, such as "Tonight" or "7h".
    func verifySelectedDaySlept(_ sleep: String, file: StaticString = #filePath, line: UInt = #line) {
        reveal(daySleep, on: content, "The day's sleep", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: daySleep) { $0.contains(sleep) },
            "The day's sleep reads \"\(daySleep.label)\", not \(sleep).",
            file: file, line: line)
    }

    /// Checks that the card shows no sleep: no sleep in the details, and the note that sleep appears when Apple Health
    /// has it.
    func verifyWeekHasNoSleep(file: StaticString = #filePath, line: UInt = #line) {
        reveal(sleepNote, on: content, "The note that sleep appears with Apple Health", file: file, line: line)
        XCTAssertFalse(daySleep.exists, "The card shows sleep, though Apple Health has none.", file: file, line: line)
    }
}
