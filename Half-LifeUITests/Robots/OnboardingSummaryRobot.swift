//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests OnboardingSummaryRobot
//

import XCTest

/// Drives onboarding's summary.
struct OnboardingSummaryRobot: Robot {
    /// The summary's identifier.
    static let screenIdentifier = OnboardingSummaryViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var title: XCUIElement { app.descendants(matching: .any)[OnboardingSummaryViewAccessibilityID.title] }
    private var content: XCUIElement { app.scrollViews[OnboardingSummaryViewAccessibilityID.content] }
    private var logFirstCupButton: XCUIElement { app.buttons[OnboardingSummaryViewAccessibilityID.logFirstCupButton] }
    private var takeMeToTodayButton: XCUIElement {
        app.buttons[OnboardingSummaryViewAccessibilityID.takeMeToTodayButton]
    }

    /// Checks that the heading names the user.
    func verifyTitle(names name: String, file: StaticString = #filePath, line: UInt = #line) {
        require(title, "The heading", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: title) { $0.contains(name) },
            "The heading reads \"\(title.label)\", without \(name).",
            file: file,
            line: line
        )
    }

    /// Checks that the summary scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Finishes onboarding and asks for the drink composer.
    func logFirstCup(file: StaticString = #filePath, line: UInt = #line) {
        require(logFirstCupButton, "Log my first cup", file: file, line: line)
        logFirstCupButton.tap()
    }

    /// Finishes onboarding.
    func takeMeToToday(file: StaticString = #filePath, line: UInt = #line) {
        require(takeMeToTodayButton, "Take me to Today", file: file, line: line)
        takeMeToTodayButton.tap()
    }
}
