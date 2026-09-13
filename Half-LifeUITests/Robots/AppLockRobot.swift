//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AppLockRobot
//

import XCTest

/// Drives `AppLockView`, the lock screen that takes the tab bar's place while the app is locked.
///
/// In UI tests, the simulated user dismisses the lock screen's own first prompt and passes every one after it, so the
/// screen stays up until the robot unlocks it. See the App Lock article's "UI tests".
struct AppLockRobot: Robot {
    /// The lock screen's identifier.
    static let screenIdentifier = AppLockViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var unlockButton: XCUIElement { app.buttons[AppLockViewAccessibilityID.unlockButton] }

    /// Asks to unlock the app, with the Unlock button.
    func unlock(file: StaticString = #filePath, line: UInt = #line) {
        require(unlockButton, "The Unlock button", file: file, line: line)
        let enabled = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: unlockButton)],
            timeout: 5)
        XCTAssertEqual(enabled, .completed, "The Unlock button stayed disabled.", file: file, line: line)
        unlockButton.tap()
    }
}
