//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests BedtimeRobot
//

import XCTest

/// Drives onboarding's bedtime step.
struct BedtimeRobot: Robot {
    /// The step's identifier.
    static let screenIdentifier = BedtimeViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var picker: XCUIElement { app.descendants(matching: .any)[BedtimeViewAccessibilityID.picker] }
    private var continueButton: XCUIElement { app.buttons[BedtimeViewAccessibilityID.continueButton] }
    private var content: XCUIElement { app.scrollViews[BedtimeViewAccessibilityID.content] }

    /// Checks that the step scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Checks that the step shows a time picker for the bedtime.
    func verifyBedtimePicker(file: StaticString = #filePath, line: UInt = #line) {
        require(picker, "The bedtime picker", file: file, line: line)
    }

    /// Saves the bedtime and moves to the next step.
    func continueToNextStep(file: StaticString = #filePath, line: UInt = #line) {
        require(continueButton, "Continue", file: file, line: line)
        continueButton.tap()
    }
}
