//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests FactorsSettingsRobot
//

import XCTest

/// Drives `FactorsSettingsView`, Settings' Caffeine and your body screen: the factors that change how fast the user
/// clears caffeine.
struct FactorsSettingsRobot: Robot {
    /// A factor with an option of its own. Pregnancy has a trimester too, so it isn't one of them.
    enum Factor {
        case estrogen, smokes, cirrhosis, fluvoxamine
    }

    /// The screen's identifier.
    static let screenIdentifier = FactorsSettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement {
        app.descendants(matching: .any)[FactorsSettingsViewAccessibilityID.screen]
    }

    private func option(_ factor: Factor) -> XCUIElement {
        switch factor {
        case .estrogen: app.buttons[FactorsSettingsViewAccessibilityID.estrogenOption]
        case .smokes: app.buttons[FactorsSettingsViewAccessibilityID.smokesOption]
        case .cirrhosis: app.buttons[FactorsSettingsViewAccessibilityID.cirrhosisOption]
        case .fluvoxamine: app.buttons[FactorsSettingsViewAccessibilityID.fluvoxamineOption]
        }
    }

    /// Chooses `factor`, or unchooses it if it's chosen.
    func chooseFactor(_ factor: Factor, file: StaticString = #filePath, line: UInt = #line) {
        let option = option(factor)
        reveal(option, on: screen, "The factor's option", file: file, line: line)
        option.tap()
    }

    /// Checks that `factor`'s option is chosen, once the saved choice has come back.
    func verifyChosen(_ factor: Factor, file: StaticString = #filePath, line: UInt = #line) {
        let option = option(factor)
        reveal(option, on: screen, "The factor's option", file: file, line: line)
        let isSelected = NSPredicate(format: "isSelected == true")
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: isSelected, object: option)], timeout: 5)
        XCTAssertEqual(result, .completed, "The option isn't chosen.", file: file, line: line)
    }
}
