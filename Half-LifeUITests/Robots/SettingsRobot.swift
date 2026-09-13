//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests SettingsRobot
//

import XCTest

/// Drives `SettingsView`, the Settings tab's root: a list of rows, each opening its own screen.
///
/// Its commands open a row's screen, and the test then resolves that screen's robot. The root scrolls under the log
/// button and the tab bar, so each command first scrolls its row into view.
struct SettingsRobot: Robot {
    /// A screen the root opens.
    enum Screen {
        case aboutYou, halfLifeFactors, bedtime, permissions, appLock, demoData
    }

    /// The root's identifier.
    static let screenIdentifier = SettingsViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    /// The root's element, which is its scroll view.
    private var screen: XCUIElement { app.descendants(matching: .any)[SettingsViewAccessibilityID.screen] }

    private func row(_ destination: Screen) -> XCUIElement {
        switch destination {
        case .aboutYou: app.buttons[SettingsViewAccessibilityID.aboutYouRow]
        case .halfLifeFactors: app.buttons[SettingsViewAccessibilityID.halfLifeFactorsRow]
        case .bedtime: app.buttons[SettingsViewAccessibilityID.bedtimeRow]
        case .permissions: app.buttons[SettingsViewAccessibilityID.permissionsRow]
        case .appLock: app.buttons[SettingsViewAccessibilityID.appLockRow]
        case .demoData: app.buttons[SettingsViewAccessibilityID.demoDataRow]
        }
    }

    /// Opens `destination` from its row.
    func open(_ destination: Screen, file: StaticString = #filePath, line: UInt = #line) {
        let row = row(destination)
        reveal(row, on: screen, "The row", file: file, line: line)
        row.tap()
    }

    /// Checks that `destination`'s row shows `text`, such as the bedtime "10:30".
    func verifyRow(_ destination: Screen, shows text: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = row(destination)
        reveal(row, on: screen, "The row", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: row) { $0.contains(text) }, "The row reads \"\(row.label)\", not \(text).", file: file,
            line: line)
    }

    /// Checks that the root's last line shows a version and a build number, such as "1.0 (1)".
    ///
    /// It checks the numbers' shape rather than their values, because the app's version isn't the UI test bundle's.
    func verifyShowsTheAppVersion(file: StaticString = #filePath, line: UInt = #line) {
        let appVersion = app.staticTexts[SettingsViewAccessibilityID.appVersion]
        reveal(appVersion, on: screen, "The app version", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: appVersion) { $0.range(of: #"\d+(\.\d+)* \(\d+\)"#, options: .regularExpression) != nil },
            "The app version reads \"\(appVersion.label)\", with no version and build.", file: file, line: line)
    }

    /// Checks that the root links to the privacy policy, under the app's version, with a link that can be tapped.
    ///
    /// It doesn't follow the link, because the policy opens outside the app, where no robot can check it.
    func verifyLinksToThePrivacyPolicy(file: StaticString = #filePath, line: UInt = #line) {
        let link = app.links[SettingsViewAccessibilityID.privacyPolicyLink]
        reveal(link, on: screen, "The privacy policy link", file: file, line: line)
        XCTAssertTrue(link.isHittable, "The privacy policy link can't be tapped.", file: file, line: line)
        let appVersion = app.staticTexts[SettingsViewAccessibilityID.appVersion]
        require(appVersion, "The app version", file: file, line: line)
        XCTAssertGreaterThanOrEqual(
            link.frame.minY, appVersion.frame.maxY, "The privacy policy link should sit under the app's version.",
            file: file, line: line)
    }
}
