//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests WelcomeRobot
//

import XCTest

/// Drives onboarding's Welcome screen.
struct WelcomeRobot: Robot {
    /// The Welcome screen's identifier.
    static let screenIdentifier = WelcomeViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var content: XCUIElement { app.scrollViews[WelcomeViewAccessibilityID.content] }
    private var getStartedButton: XCUIElement { app.buttons[WelcomeViewAccessibilityID.getStartedButton] }

    /// Checks that the screen scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Starts onboarding.
    func getStarted(file: StaticString = #filePath, line: UInt = #line) {
        require(getStartedButton, "Get started", file: file, line: line)
        getStartedButton.tap()
    }
}
