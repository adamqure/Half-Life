//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests AppRobot
//

import XCTest

/// Drives `AppView`, the app's root screen: its tab bar and its log button.
struct AppRobot: Robot {
    /// The root screen's identifier.
    static let screenIdentifier = AppViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var logButton: XCUIElement { app.buttons[AppViewAccessibilityID.logButton] }

    /// The system tab bar's buttons carry no accessibility identifier, however it's set, so this robot finds each by
    /// its title: its `AppTab` key's text in the String Catalog, read from this test bundle's copy in the development
    /// language the UI tests run the app in. It's the one exception to finding elements by identifier, and only this
    /// robot makes it (constitution Article II.6).
    private var todayTab: XCUIElement { app.tabBars.buttons[AppTab.today.title(in: Self.developmentLanguage)] }
    private var settingsTab: XCUIElement { app.tabBars.buttons[AppTab.settings.title(in: Self.developmentLanguage)] }
    private var insightsTab: XCUIElement { app.tabBars.buttons[AppTab.insights.title(in: Self.developmentLanguage)] }

    /// The UI test bundle's String Catalog in the development language, English.
    private static let developmentLanguage: Bundle = {
        let tests = Bundle(for: BundleToken.self)
        return tests.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:)) ?? tests
    }()

    /// Opens the drink composer with the log button.
    func openDrinkComposer(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(logButton.waitForExistence(timeout: 5), "The log button isn't showing.", file: file, line: line)
        logButton.tap()
    }

    /// Opens the Insights tab.
    func openInsights(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            insightsTab.waitForExistence(timeout: 5), "The Insights tab isn't showing.", file: file, line: line)
        insightsTab.tap()
    }

    /// Opens the Settings tab.
    func openSettings(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            settingsTab.waitForExistence(timeout: 5), "The Settings tab isn't showing.", file: file, line: line)
        settingsTab.tap()
    }

    /// Opens the Today tab.
    func openToday(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "The Today tab isn't showing.", file: file, line: line)
        todayTab.tap()
    }
}

/// A class in the UI test bundle, so the robot can find the bundle and its String Catalog.
private final class BundleToken {}
