//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AppRobot
//

import XCTest

/// Drives `AppView`, the app's root screen, and its log button.
struct AppRobot: Robot {
    /// The root screen's identifier.
    static let screenIdentifier = AppViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var logButton: XCUIElement { app.buttons[AppViewAccessibilityID.logButton] }

    /// Opens the drink composer with the log button.
    func openDrinkComposer(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(logButton.waitForExistence(timeout: 5), "The log button isn't showing.", file: file, line: line)
        logButton.tap()
    }
}
