//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests BedtimeSettingsRobot
//

import XCTest

/// Drives `BedtimeSettingsView`, Settings' Bedtime screen: the system's time picker.
struct BedtimeSettingsRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = BedtimeSettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { app.descendants(matching: .any)[BedtimeSettingsViewAccessibilityID.screen] }
    private var picker: XCUIElement { app.datePickers[BedtimeSettingsViewAccessibilityID.picker] }

    /// Checks that the bedtime's time picker is showing.
    func verifyShowsTheBedtime(file: StaticString = #filePath, line: UInt = #line) {
        reveal(picker, on: screen, "The bedtime's time picker", file: file, line: line)
    }
}
