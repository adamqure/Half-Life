//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests Half_LifeUITests
//

import XCTest

final class Half_LifeUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    /// Launching the app shows the root screen.
    @MainActor
    func testLaunchShowsTheRootScreen() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        _ = try app.resolve(AppRobot.self)
    }

    /// Constitution Article VI.4: every screen passes the system accessibility audit.
    @MainActor
    func testRootScreenPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()

        // The owner approved this on 2026-09-12. At launch, contrast is ignored only for elements under the tab bar
        // or in its fade, and for issues with no element. Then the screen scrolls to its end, and the second audit
        // ignores nothing.
        // See auditAccessibilityAboveTheTabBar.
        try app.resolve(AppRobot.self).auditAccessibilityAboveTheTabBar()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launchPastOnboarding()
        }
    }
}
