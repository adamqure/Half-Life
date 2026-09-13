//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests StepsDetailRobot
//

import XCTest

/// Drives `StepsDetailView`, the steps screen the Insights tab's steps button opens: the steps on days after a
/// caffeine night, against the other days.
struct StepsDetailRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = StepsDetailViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var title: XCUIElement { app.descendants(matching: .any)[StepsDetailViewAccessibilityID.title] }
    private var verdict: XCUIElement { app.descendants(matching: .any)[StepsDetailViewAccessibilityID.verdict] }
    private var afterCaffeine: XCUIElement {
        app.descendants(matching: .any)[StepsDetailViewAccessibilityID.afterCaffeine]
    }
    private var otherDays: XCUIElement { app.descendants(matching: .any)[StepsDetailViewAccessibilityID.otherDays] }
    private var chart: XCUIElement { app.descendants(matching: .any)[StepsDetailViewAccessibilityID.chart] }
    private var definition: XCUIElement {
        app.descendants(matching: .any)[StepsDetailViewAccessibilityID.definition]
    }

    /// Checks that the screen is the steps screen, titled "Steps".
    func verifyIsSteps(file: StaticString = #filePath, line: UInt = #line) {
        require(title, "The screen's title", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: title) { $0 == "Steps" }, "The screen is titled \"\(title.label)\", not Steps.",
            file: file, line: line)
    }

    /// Checks that the screen says there are too few days to compare yet.
    func verifyTooFewDaysToCompare(file: StaticString = #filePath, line: UInt = #line) {
        require(verdict, "The verdict", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: verdict) { $0 == "Too few days to compare yet" },
            "The verdict reads \"\(verdict.label)\", not that there are too few days.", file: file, line: line)
    }

    /// Checks that there's no day after a caffeine night to average.
    func verifyNoDaysAfterACaffeineNight(file: StaticString = #filePath, line: UInt = #line) {
        require(afterCaffeine, "The days after a caffeine night", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: afterCaffeine) { $0.contains("None yet") },
            "The days after a caffeine night read \"\(afterCaffeine.label)\", not None yet.", file: file, line: line)
    }

    /// Checks that the other days average `steps`, as shown, such as "8,420", over `days` days.
    func verifyOtherDays(averaging steps: String, over days: Int, file: StaticString = #filePath, line: UInt = #line) {
        require(otherDays, "The other days", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: otherDays) { $0.contains("\(steps) steps") && $0.contains("\(days) days") },
            "The other days read \"\(otherDays.label)\", not \(steps) steps over \(days) days.", file: file,
            line: line)
    }

    /// Checks that the screen says what a caffeine night is, in words rather than an amount.
    func verifyDefinesACaffeineNight(file: StaticString = #filePath, line: UInt = #line) {
        let expected =
            "A caffeine night is one with more than your recommended caffeine in you when you fell asleep, "
            + "or at your bedtime if Apple Health has no sleep that night."
        require(definition, "What a caffeine night is", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: definition) { $0 == expected },
            "The definition reads \"\(definition.label)\", not \"\(expected)\".", file: file, line: line)
    }

    /// Checks that the screen draws the 30 days' steps.
    func verifyHasTheDaysChart(file: StaticString = #filePath, line: UInt = #line) {
        require(chart, "The chart of the last 30 days", file: file, line: line)
    }
}
