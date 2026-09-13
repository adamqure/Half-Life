//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AboutYouSettingsRobot
//

import XCTest

/// Drives `AboutYouSettingsView`, Settings' About you screen: the name and the age.
struct AboutYouSettingsRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = AboutYouSettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { app.descendants(matching: .any)[AboutYouSettingsViewAccessibilityID.screen] }
    /// The name field wraps, so it may be a text view rather than a text field.
    private var nameField: XCUIElement {
        app.descendants(matching: .any)[AboutYouSettingsViewAccessibilityID.nameField]
    }

    /// Replaces the name with `name`, and presses Return, which saves it. The field wraps, so Return types a newline,
    /// which the app takes as committing the name.
    func enterName(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        reveal(nameField, on: screen, "The name field", file: file, line: line)
        nameField.tap()
        let typed = (nameField.value as? String) ?? ""
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: typed.count) + name + "\n")
    }
}
