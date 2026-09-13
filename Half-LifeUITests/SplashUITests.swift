//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests SplashUITests
//

import XCTest

/// Drives the splash screen against UI-SPLASH-1 and UI-SPLASH-2 in the Splash Screen article.
///
/// Each test holds the launch, so the splash stays up: the simulated app lock's setting never answers.
final class SplashUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// UI-SPLASH-1: while the app launches, the splash screen names the app and shows that it's loading, and passes
    /// the audit.
    @MainActor
    func testTheSplashScreenShowsWhileTheAppLaunches() throws {
        let app = XCUIApplication()
        app.launchHoldingTheSplash()

        let splash = try app.resolve(SplashRobot.self)
        splash.verifyShowsLoading()
        try splash.auditAccessibility()
    }

    /// UI-SPLASH-2: at the largest accessibility text size, the splash screen still names the app, and passes the
    /// audit.
    @MainActor
    func testTheSplashScreenPassesTheAuditWithTheLargestText() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchHoldingTheSplash()

        let splash = try app.resolve(SplashRobot.self)
        splash.verifyShowsLoading()
        try splash.auditAccessibility()
    }
}
