//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests HeartRateDetailRobot
//

import XCTest

/// Drives `HeartRateDetailView`, the screen the Insights tab's resting heart rate button opens.
struct HeartRateDetailRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = HeartRateDetailViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement {
        app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.screen]
    }
    private var title: XCUIElement { app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.title] }
    private var headline: XCUIElement {
        app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.headline]
    }
    private var afterCaffeine: XCUIElement {
        app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.afterCaffeine]
    }
    private var otherDays: XCUIElement {
        app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.otherDays]
    }
    private var chart: XCUIElement { app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.chart] }
    private var footnote: XCUIElement {
        app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.footnote]
    }
    private var source: XCUIElement {
        app.descendants(matching: .any)[HeartRateDetailViewAccessibilityID.source]
    }

    /// Checks that the screen is titled "Resting heart rate".
    func verifyTitle(file: StaticString = #filePath, line: UInt = #line) {
        require(title, "The screen's title", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: title) { $0 == "Resting heart rate" }, "The screen is titled \"\(title.label)\".",
            file: file, line: line)
    }

    /// Checks that the headline says there aren't enough days yet, as it does before 5 days follow caffeine nights.
    func verifyNotEnoughDaysYet(file: StaticString = #filePath, line: UInt = #line) {
        require(headline, "The headline", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: headline) { $0.contains("Not enough days") },
            "The headline reads \"\(headline.label)\", not that there aren't enough days yet.", file: file, line: line)
    }

    /// Checks that the screen shows what it compares: both groups and the chart of each day, and the footnote that
    /// says the comparison isn't proof.
    func verifyShowsTheComparison(file: StaticString = #filePath, line: UInt = #line) {
        require(headline, "The headline", file: file, line: line)
        for (element, name) in [
            (afterCaffeine, "The days after a caffeine night"), (otherDays, "The other days"), (chart, "The chart"),
            (footnote, "The footnote"),
        ] {
            reveal(element, on: screen, name, file: file, line: line)
        }
    }

    /// Checks that the data is said to come from Apple Health, or from the demo when `isDemo` is true.
    func verifySource(isDemo: Bool, file: StaticString = #filePath, line: UInt = #line) {
        reveal(source, on: screen, "Where the data comes from", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: source) { $0.contains(isDemo ? "Demo" : "Apple Health") },
            "The source reads \"\(source.label)\".", file: file, line: line)
    }
}
