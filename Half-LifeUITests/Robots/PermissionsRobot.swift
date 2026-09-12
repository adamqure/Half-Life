//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests PermissionsRobot
//

import XCTest

/// Drives onboarding's permissions step. Under UI tests, the app simulates each permission, so no system prompt
/// appears.
struct PermissionsRobot: Robot {
    /// The step's identifier.
    static let screenIdentifier = PermissionsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var healthAllowButton: XCUIElement { app.buttons[PermissionsViewAccessibilityID.healthAllowButton] }
    private var healthStatus: XCUIElement {
        app.descendants(matching: .any)[PermissionsViewAccessibilityID.healthStatus]
    }
    private var notificationsAllowButton: XCUIElement {
        app.buttons[PermissionsViewAccessibilityID.notificationsAllowButton]
    }
    private var notificationsStatus: XCUIElement {
        app.descendants(matching: .any)[PermissionsViewAccessibilityID.notificationsStatus]
    }
    private var biometricsAllowButton: XCUIElement { app.buttons[PermissionsViewAccessibilityID.biometricsAllowButton] }
    private var biometricsStatus: XCUIElement {
        app.descendants(matching: .any)[PermissionsViewAccessibilityID.biometricsStatus]
    }
    private var continueButton: XCUIElement { app.buttons[PermissionsViewAccessibilityID.continueButton] }
    private var content: XCUIElement { app.scrollViews[PermissionsViewAccessibilityID.content] }

    /// Asks for Apple Health.
    func allowHealth(file: StaticString = #filePath, line: UInt = #line) {
        require(healthAllowButton, "Apple Health's Allow button", file: file, line: line)
        healthAllowButton.tap()
    }

    /// Asks for notifications.
    func allowNotifications(file: StaticString = #filePath, line: UInt = #line) {
        require(notificationsAllowButton, "The notifications' Allow button", file: file, line: line)
        notificationsAllowButton.tap()
    }

    /// Asks for Face ID or Touch ID.
    func allowBiometrics(file: StaticString = #filePath, line: UInt = #line) {
        require(biometricsAllowButton, "Face ID's Allow button", file: file, line: line)
        biometricsAllowButton.tap()
    }

    /// Checks that Apple Health says it has been asked, the most the app can know.
    func verifyHealthAsked(file: StaticString = #filePath, line: UInt = #line) {
        verify(healthStatus, reads: "Asked", file: file, line: line)
    }

    /// Checks that notifications are on.
    func verifyNotificationsOn(file: StaticString = #filePath, line: UInt = #line) {
        verify(notificationsStatus, reads: "On", file: file, line: line)
    }

    /// Checks that Face ID or Touch ID is on.
    func verifyBiometricsOn(file: StaticString = #filePath, line: UInt = #line) {
        verify(biometricsStatus, reads: "On", file: file, line: line)
    }

    /// Checks that the step scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Moves to the next step, whatever was allowed.
    func continueToNextStep(file: StaticString = #filePath, line: UInt = #line) {
        require(continueButton, "Continue", file: file, line: line)
        continueButton.tap()
    }

    private func verify(_ status: XCUIElement, reads text: String, file: StaticString, line: UInt) {
        require(status, "The status", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: status) { $0 == text },
            "The status reads \"\(status.label)\", not \"\(text)\".",
            file: file,
            line: line
        )
    }
}
