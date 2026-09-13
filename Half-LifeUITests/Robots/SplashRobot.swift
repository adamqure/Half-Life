//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests SplashRobot
//

import XCTest

/// Drives `SplashView`, the screen the app shows while it launches.
///
/// A normal launch passes it too quickly to check, so its tests hold the launch with `launchHoldingTheSplash()`.
struct SplashRobot: Robot {
    /// The splash screen's identifier.
    static let screenIdentifier = SplashViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var wordmark: XCUIElement { app.staticTexts[SplashViewAccessibilityID.wordmark] }
    private var progress: XCUIElement { app.activityIndicators[SplashViewAccessibilityID.progress] }

    /// Checks that the splash names the app and shows that it's loading, once the launch has run long enough to show
    /// them. Then it waits for the two to finish fading in, so an audit that follows reads their final colors.
    func verifyShowsLoading(file: StaticString = #filePath, line: UInt = #line) {
        require(wordmark, "The app's name", file: file, line: line)
        require(progress, "The loading indicator", file: file, line: line)
        waitUntilStill(wordmark)
    }

    /// Waits until three pictures of `element` in a row are identical, or 30 have been taken, so its fade has ended. It
    /// waits for that condition, not for a fixed time (constitution Article II.9). It watches the name alone, because
    /// the loading indicator beneath it never stops turning.
    private func waitUntilStill(_ element: XCUIElement) {
        var previous = element.screenshot().pngRepresentation
        var identicalInARow = 0
        for _ in 0..<30 {
            let current = element.screenshot().pngRepresentation
            identicalInARow = current == previous ? identicalInARow + 1 : 0
            if identicalInARow >= 2 { return }
            previous = current
        }
    }
}
