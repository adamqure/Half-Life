//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests PermissionSettingsRobot
//

import XCTest

/// Drives `PermissionSettingsView`, Settings' Permissions screen: Apple Health, notifications, and Face ID or Touch ID.
struct PermissionSettingsRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = PermissionSettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { app.descendants(matching: .any)[PermissionSettingsViewAccessibilityID.screen] }
    private var healthAllowButton: XCUIElement { app.buttons[PermissionSettingsViewAccessibilityID.healthAllowButton] }
    private var healthStatus: XCUIElement {
        app.descendants(matching: .any)[PermissionSettingsViewAccessibilityID.healthStatus]
    }
    private var notificationsAllowButton: XCUIElement {
        app.buttons[PermissionSettingsViewAccessibilityID.notificationsAllowButton]
    }
    private var notificationsStatus: XCUIElement {
        app.descendants(matching: .any)[PermissionSettingsViewAccessibilityID.notificationsStatus]
    }

    /// Asks to read Apple Health.
    func allowHealth(file: StaticString = #filePath, line: UInt = #line) {
        reveal(healthAllowButton, on: screen, "The Apple Health Allow button", file: file, line: line)
        healthAllowButton.tap()
    }

    /// Asks to send notifications.
    func allowNotifications(file: StaticString = #filePath, line: UInt = #line) {
        reveal(notificationsAllowButton, on: screen, "The notifications Allow button", file: file, line: line)
        notificationsAllowButton.tap()
    }

    /// Checks that the Apple Health card says Half-Life has asked.
    func verifyHealthAsked(file: StaticString = #filePath, line: UInt = #line) {
        verify(healthStatus, reads: "Asked", file: file, line: line)
    }

    /// Checks that the notifications card says they're on.
    func verifyNotificationsOn(file: StaticString = #filePath, line: UInt = #line) {
        verify(notificationsStatus, reads: "On", file: file, line: line)
    }

    private func verify(_ status: XCUIElement, reads text: String, file: StaticString, line: UInt) {
        reveal(status, on: screen, "The status", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: status) { $0.contains(text) }, "The status reads \"\(status.label)\", not \(text).",
            file: file, line: line)
    }
}
