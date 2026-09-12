//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests DrinkComposerUITests
//

import XCTest

/// Scenarios for the drink composer, opened from the root screen's log button.
final class DrinkComposerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app and opens the composer.
    @MainActor
    private func openComposer(in app: XCUIApplication) throws -> DrinkComposerRobot {
        app.launch()
        try app.resolve(AppRobot.self).openDrinkComposer()
        return try app.resolve(DrinkComposerRobot.self)
    }

    /// The composer opens with a drink chosen and its panel showing. Which drink depends on the device's drink log.
    @MainActor
    func testOpensWithADrinkChosen() throws {
        let composer = try openComposer(in: XCUIApplication())

        composer.verifyADrinkIsChosen()
    }

    /// The composer's sheet is only as tall as its content.
    @MainActor
    func testOpensAsACompactSheet() throws {
        let composer = try openComposer(in: XCUIApplication())

        composer.verifyIsCompact()
    }

    @MainActor
    func testChoosingALatteStartsAtTwoShots() throws {
        let composer = try openComposer(in: XCUIApplication())

        composer.selectDrink(.latte)

        composer.verifyQuantity("2 shots")
        composer.verifyEstimate("125 mg")
    }

    @MainActor
    func testTheStepperChangesTheEstimate() throws {
        let composer = try openComposer(in: XCUIApplication())
        composer.selectDrink(.latte)

        composer.addOneUnit()
        composer.verifyQuantity("3 shots")
        composer.verifyEstimate("188 mg")

        composer.removeOneUnit()
        composer.removeOneUnit()
        composer.removeOneUnit()
        composer.verifyQuantity("1 shot")
        composer.verifyEstimate("63 mg")
    }

    @MainActor
    func testChoosingWhenTheDrinkWasConsumed() throws {
        let composer = try openComposer(in: XCUIApplication())
        composer.selectDrink(.coldBrew)
        composer.verifyChosen(.now)

        composer.choose(.twoHoursAgo)

        composer.verifyChosen(.twoHoursAgo)
    }

    @MainActor
    func testClosingReturnsToTheRootScreen() throws {
        let app = XCUIApplication()
        let composer = try openComposer(in: app)

        composer.close()

        composer.verifyClosed()
        _ = try app.resolve(AppRobot.self)
    }

    /// Constitution Article VI.4: the composer, with a drink chosen, passes the system accessibility audit.
    @MainActor
    func testComposerPassesAccessibilityAudit() throws {
        let composer = try openComposer(in: XCUIApplication())
        composer.selectDrink(.latte)

        // The owner approved skipping these two checks, and only these, on 2026-09-12.
        // - Text clipping: the sheet's height follows the text size, which the audit's static check can't see, so it
        //   flags text that isn't clipped. testLargestTextKeepsEveryControlOnScreen checks the real behavior instead.
        // - Element detection: the Today screen's text shows, dimmed, above the small sheet. iOS hides that screen from
        //   VoiceOver while the sheet is open, so the audit finds text with no accessibility element. The root
        //   screen's own audit covers that text.
        try composer.auditAccessibility(except: [.textClipped, .elementDetection])
    }

    /// At an accessibility text size, the sheet grows with its content, and every control stays fully on screen.
    @MainActor
    func testLargestTextKeepsEveryControlOnScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        let composer = try openComposer(in: app)

        composer.verifyEveryControlIsOnScreen()
    }
}
