//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests DemoHistorySettingsRobot
//

import XCTest

/// Drives `DemoHistorySettingsView`, Settings' Demo data screen: the button that adds or removes the demo drinks.
struct DemoHistorySettingsRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = DemoHistorySettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { app.descendants(matching: .any)[DemoHistorySettingsViewAccessibilityID.screen] }
    private var addDemoButton: XCUIElement { app.buttons[DemoHistorySettingsViewAccessibilityID.addDemoButton] }
    private var removeDemoButton: XCUIElement { app.buttons[DemoHistorySettingsViewAccessibilityID.removeDemoButton] }
    private var demoHealthDataOption: XCUIElement {
        app.buttons[DemoHistorySettingsViewAccessibilityID.demoHealthDataOption]
    }

    /// Turns the demo Health data on or off, so the Today screen's Apple Health card shows demo data or Apple
    /// Health's, and waits for the switch to follow.
    func turnDemoHealthData(on isOn: Bool, file: StaticString = #filePath, line: UInt = #line) {
        reveal(demoHealthDataOption, on: screen, "The demo Health data option", file: file, line: line)
        if demoHealthDataOption.isSelected != isOn {
            demoHealthDataOption.tap()
        }
        let followed = NSPredicate { _, _ in demoHealthDataOption.isSelected == isOn }
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: followed, object: nil)], timeout: 5),
            .completed, "The demo Health data didn't turn \(isOn ? "on" : "off").", file: file, line: line)
    }

    /// Adds 30 days of demo drinks.
    func addDemoDrinks(file: StaticString = #filePath, line: UInt = #line) {
        reveal(addDemoButton, on: screen, "The button that adds the demo drinks", file: file, line: line)
        addDemoButton.tap()
    }

    /// Removes the demo drinks.
    func removeDemoDrinks(file: StaticString = #filePath, line: UInt = #line) {
        reveal(removeDemoButton, on: screen, "The button that removes the demo drinks", file: file, line: line)
        removeDemoButton.tap()
    }

    /// Checks whether the screen offers to remove the demo drinks, which it does only while the log holds some.
    func verifyHasDemoDrinks(_ hasDemoDrinks: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let button = hasDemoDrinks ? removeDemoButton : addDemoButton
        reveal(button, on: screen, hasDemoDrinks ? "The remove button" : "The add button", file: file, line: line)
        XCTAssertTrue(
            button.exists,
            hasDemoDrinks ? "Settings doesn't offer to remove the demo drinks." : "Settings doesn't offer to add them.",
            file: file, line: line)
    }
}
