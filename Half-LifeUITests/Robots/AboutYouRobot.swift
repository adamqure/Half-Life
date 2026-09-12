//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AboutYouRobot
//

import XCTest

/// Drives onboarding's About you step.
struct AboutYouRobot: Robot {
    /// The About you screen's identifier.
    static let screenIdentifier = AboutYouViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var nameField: XCUIElement { app.textFields[AboutYouViewAccessibilityID.nameField] }
    private var agePicker: XCUIElement { app.descendants(matching: .any)[AboutYouViewAccessibilityID.agePicker] }
    private var continueButton: XCUIElement { app.buttons[AboutYouViewAccessibilityID.continueButton] }
    private var content: XCUIElement { app.scrollViews[AboutYouViewAccessibilityID.content] }

    /// Checks that the step scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Types the user's first name, then closes the keyboard.
    func enterName(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        require(nameField, "The name field", file: file, line: line)
        nameField.tap()
        nameField.typeText(name + "\n")
    }

    /// Chooses the user's age on the picker.
    func chooseAge(_ age: Int, file: StaticString = #filePath, line: UInt = #line) {
        require(agePicker, "The age picker", file: file, line: line)
        let wheel = agePicker.elementType == .pickerWheel ? agePicker : agePicker.pickerWheels.firstMatch
        wheel.adjust(toPickerWheelValue: "\(age)")
    }

    /// Saves the answers and moves to the next step.
    func continueToNextStep(file: StaticString = #filePath, line: UInt = #line) {
        require(continueButton, "Continue", file: file, line: line)
        continueButton.tap()
    }
}
