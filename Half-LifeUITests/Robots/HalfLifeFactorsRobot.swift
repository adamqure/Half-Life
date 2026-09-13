//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests HalfLifeFactorsRobot
//

import XCTest

/// Drives onboarding's step about what changes how fast the user clears caffeine.
struct HalfLifeFactorsRobot: Robot {
    /// A factor other than pregnancy.
    enum Factor {
        case estrogen, smokes, cirrhosis, fluvoxamine
    }

    /// A trimester of a pregnancy.
    enum Trimester {
        case first, second, third
    }

    /// The step's identifier.
    static let screenIdentifier = HalfLifeFactorsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var pregnantOption: XCUIElement { app.buttons[HalfLifeFactorsViewAccessibilityID.pregnantOption] }
    private var continueButton: XCUIElement { app.buttons[HalfLifeFactorsViewAccessibilityID.continueButton] }
    private var content: XCUIElement { app.scrollViews[HalfLifeFactorsViewAccessibilityID.content] }

    private func option(_ factor: Factor) -> XCUIElement {
        switch factor {
        case .estrogen: app.buttons[HalfLifeFactorsViewAccessibilityID.estrogenOption]
        case .smokes: app.buttons[HalfLifeFactorsViewAccessibilityID.smokesOption]
        case .cirrhosis: app.buttons[HalfLifeFactorsViewAccessibilityID.cirrhosisOption]
        case .fluvoxamine: app.buttons[HalfLifeFactorsViewAccessibilityID.fluvoxamineOption]
        }
    }

    private func choice(_ trimester: Trimester) -> XCUIElement {
        switch trimester {
        case .first: app.buttons[HalfLifeFactorsViewAccessibilityID.firstTrimester]
        case .second: app.buttons[HalfLifeFactorsViewAccessibilityID.secondTrimester]
        case .third: app.buttons[HalfLifeFactorsViewAccessibilityID.thirdTrimester]
        }
    }

    /// Chooses a factor, or unchooses it if it's chosen.
    func choose(_ factor: Factor, file: StaticString = #filePath, line: UInt = #line) {
        let element = option(factor)
        require(element, "The option", file: file, line: line)
        element.tap()
    }

    /// Says the user is pregnant, in `trimester`.
    func choosePregnancy(trimester: Trimester, file: StaticString = #filePath, line: UInt = #line) {
        require(pregnantOption, "The pregnancy option", file: file, line: line)
        pregnantOption.tap()
        let element = choice(trimester)
        require(element, "The trimester choice", file: file, line: line)
        element.tap()
    }

    /// Checks that pregnancy is chosen, in `trimester`, once the saved choice has come back.
    func verifyPregnancy(trimester: Trimester, file: StaticString = #filePath, line: UInt = #line) {
        let element = choice(trimester)
        require(element, "The trimester choice", file: file, line: line)
        let isSelected = NSPredicate(format: "isSelected == true")
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: isSelected, object: element)], timeout: 5)
        XCTAssertEqual(result, .completed, "The trimester isn't chosen.", file: file, line: line)
    }

    /// Checks that `factor`'s option is chosen, once the saved choice has come back.
    func verifyChosen(_ factor: Factor, file: StaticString = #filePath, line: UInt = #line) {
        let element = option(factor)
        require(element, "The option", file: file, line: line)
        let isSelected = NSPredicate(format: "isSelected == true")
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: isSelected, object: element)], timeout: 5)
        XCTAssertEqual(result, .completed, "The option isn't chosen.", file: file, line: line)
    }

    /// Checks that the step scrolls only vertically, even when swiped sideways.
    func verifyScrollsOnlyVertically(file: StaticString = #filePath, line: UInt = #line) {
        verifyScrollsOnlyVertically(content, file: file, line: line)
    }

    /// Moves to the next step.
    func continueToNextStep(file: StaticString = #filePath, line: UInt = #line) {
        require(continueButton, "Continue", file: file, line: line)
        continueButton.tap()
    }
}
