//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests SiriShortcutsRobot
//

import XCTest

/// Drives onboarding's "Use Siri and Shortcuts" step: the phrases to try, the Shortcuts button, and Continue.
struct SiriShortcutsRobot: Robot {
    /// The step's identifier.
    static let screenIdentifier = SiriShortcutsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var logPhrase: XCUIElement { app.descendants(matching: .any)[SiriShortcutsViewAccessibilityID.logPhrase] }
    private var levelPhrase: XCUIElement {
        app.descendants(matching: .any)[SiriShortcutsViewAccessibilityID.levelPhrase]
    }
    private var sleepPhrase: XCUIElement {
        app.descendants(matching: .any)[SiriShortcutsViewAccessibilityID.sleepPhrase]
    }
    private var askPhrase: XCUIElement { app.descendants(matching: .any)[SiriShortcutsViewAccessibilityID.askPhrase] }
    private var shortcutsLink: XCUIElement { app.buttons[SiriShortcutsViewAccessibilityID.shortcutsLink] }
    private var continueButton: XCUIElement { app.buttons[SiriShortcutsViewAccessibilityID.continueButton] }
    private var content: XCUIElement { app.scrollViews[SiriShortcutsViewAccessibilityID.content] }

    /// Checks that the step shows a phrase to try for logging, the caffeine level, the sleep time, and a question.
    func verifyPhrasesToTry(file: StaticString = #filePath, line: UInt = #line) {
        require(logPhrase, "The phrase for logging a drink", file: file, line: line)
        require(levelPhrase, "The phrase for the caffeine level", file: file, line: line)
        require(sleepPhrase, "The phrase for the sleep time", file: file, line: line)
        require(askPhrase, "The phrase for asking a question", file: file, line: line)
    }

    /// Checks that the step offers the Shortcuts app's button, and that its label names the app.
    func verifyShortcutsButtonNamesTheApp(file: StaticString = #filePath, line: UInt = #line) {
        require(shortcutsLink, "The Shortcuts button", file: file, line: line)
        XCTAssertTrue(
            shortcutsLink.label.contains("Half-Life"),
            "The Shortcuts button's label should name Half-Life, but it's '\(shortcutsLink.label)'.",
            file: file, line: line)
    }

    /// Runs the accessibility audit on the step, excusing only clipped text inside Apple's Shortcuts button.
    ///
    /// `ShortcutsLink` draws its own label, "Half-Life shortcuts", and the audit reports it clipped, however much room
    /// the step gives the button. The app can't change the control's text or layout, so the owner chose on 2026-09-13
    /// to keep the button and excuse that one issue. Every other issue fails, including any other issue on the button.
    /// The button is found by its identifier, and an issue is excused only if its element lies within the button's
    /// frame (constitution Article II.6).
    func auditAccessibilityExcusingTheShortcutsButton(file: StaticString = #filePath, line: UInt = #line) throws {
        require(shortcutsLink, "The Shortcuts button", file: file, line: line)
        let button = shortcutsLink.frame.insetBy(dx: -1, dy: -1)
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .textClipped, let element = issue.element else { return false }
            return button.contains(element.frame)
        }
    }

    /// Checks that the step scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Moves to the next step. The step asks for nothing.
    func continueToNextStep(file: StaticString = #filePath, line: UInt = #line) {
        require(continueButton, "Continue", file: file, line: line)
        continueButton.tap()
    }
}
