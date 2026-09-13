//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AppLockSettingsRobot
//

import XCTest

/// Drives `AppLockSettingsView`, Settings' App lock screen: the option that turns the lock on or off.
struct AppLockSettingsRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = AppLockSettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { app.descendants(matching: .any)[AppLockSettingsViewAccessibilityID.screen] }
    private var appLockOption: XCUIElement { app.buttons[AppLockSettingsViewAccessibilityID.appLockOption] }

    /// Turns the app lock on, or off if it's on.
    func switchAppLock(file: StaticString = #filePath, line: UInt = #line) {
        reveal(appLockOption, on: screen, "The app lock option", file: file, line: line)
        appLockOption.tap()
    }

    /// Checks whether the app lock is on: its option is selected only while it is.
    func verifyAppLockOn(_ isOn: Bool, file: StaticString = #filePath, line: UInt = #line) {
        reveal(appLockOption, on: screen, "The app lock option", file: file, line: line)
        let selected = NSPredicate(format: "isSelected == %@", NSNumber(value: isOn))
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: selected, object: appLockOption)], timeout: 5)
        XCTAssertEqual(result, .completed, "The app lock isn't \(isOn ? "on" : "off").", file: file, line: line)
    }
}
