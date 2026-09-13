//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AppLockUITests
//

import XCTest

/// Drives the app lock against UI-LOCK-1 in the App Lock article.
///
/// Each test launches past onboarding, with simulated permissions and the simulated lock: its setting starts off, and
/// its simulated user dismisses the first unlock prompt and passes every one after it.
final class AppLockUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// UI-LOCK-1: turning the lock on in Settings, leaving the app, and coming back shows the lock screen, which
    /// passes the audit. Unlocking shows the app again, with the lock still on.
    @MainActor
    func testTheLockHidesTheAppOnceItLeavesAndUnlocks() throws {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(SettingsRobot.self).open(.appLock)
        let appLockSettings = try app.resolve(AppLockSettingsRobot.self)
        appLockSettings.switchAppLock()
        appLockSettings.verifyAppLockOn(true)

        app.leaveAndComeBack()

        // The lock screen's own first prompt is declined, so it stays up.
        let lock = try app.resolve(AppLockRobot.self)
        try lock.auditAccessibility()
        lock.unlock()

        // The lock screen took the tab bar's place, so unlocking builds the tab bar again, on Today. Settings keeps its
        // pushed App lock screen in the store, so it's still showing when the Settings tab opens.
        try app.resolve(AppRobot.self).openSettings()
        try app.resolve(AppLockSettingsRobot.self).verifyAppLockOn(true)
    }
}
