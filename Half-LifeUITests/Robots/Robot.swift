//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests Robot
//

import XCTest

/// A screen that UI tests drive through semantic commands and verifications (constitution Article II.5–11).
///
/// Tests never touch a robot's elements. They resolve the robot that's on screen with
/// `XCUIApplication.resolve(_:timeout:)` or `resolve(expecting:timeout:)`, then call its commands.
@MainActor
protocol Robot {
    /// The accessibility identifier of the screen's root element, taken from the view's `<View>AccessibilityID`.
    static var screenIdentifier: String { get }

    /// The app the robot drives.
    var app: XCUIApplication { get }

    /// Creates the robot for its screen in `app`.
    init(app: XCUIApplication)
}

extension Robot {
    /// Runs the system accessibility audit on the robot's screen (constitution Article VI.4).
    func auditAccessibility() throws {
        try app.performAccessibilityAudit()
    }

    /// Captures the screen as it looks now.
    func screenshot() -> XCUIScreenshot {
        app.screenshot()
    }
}

/// Every robot in the suite. Resolution uses it to name the screen that's showing when a test's expectation fails.
///
/// Add each new robot here.
enum Robots {
    /// All robots, one per screen.
    static let all: [any Robot.Type] = [AppRobot.self, DrinkComposerRobot.self, TodayRobot.self]
}

/// The error thrown when none of the screens a test expected appears.
struct UnexpectedScreenError: Error, Equatable, CustomStringConvertible {
    /// The names of the robots the test expected.
    let expected: [String]
    /// The name of the known robot whose screen is showing, or `nil` if no known robot recognizes it.
    let showing: String?

    /// A readable failure message naming what was expected and what is showing.
    var description: String {
        let showingDescription = showing.map { "\($0) is showing" } ?? "no known screen is showing"
        return "Expected \(expected.joined(separator: " or ")), but \(showingDescription)."
    }
}

@MainActor
extension XCUIApplication {
    /// Waits for `robot`'s screen and returns the robot.
    ///
    /// - Throws: ``UnexpectedScreenError`` if the screen doesn't appear within `timeout`.
    func resolve<R: Robot>(_ robot: R.Type, timeout: TimeInterval = 5) throws -> R {
        _ = try waitForScreen(of: [robot], timeout: timeout)
        return R(app: self)
    }

    /// Waits for one of the `expected` robots' screens and returns that robot.
    ///
    /// If more than one expected screen is showing, the first in `expected` wins.
    ///
    /// - Throws: ``UnexpectedScreenError`` if none of the screens appears within `timeout`.
    func resolve(expecting expected: [any Robot.Type], timeout: TimeInterval = 5) throws -> any Robot {
        try waitForScreen(of: expected, timeout: timeout).init(app: self)
    }

    private func waitForScreen(of expected: [any Robot.Type], timeout: TimeInterval) throws -> any Robot.Type {
        let identifiers = expected.map { $0.screenIdentifier }
        _ = descendants(matching: .any)
            .matching(NSPredicate(format: "identifier IN %@", identifiers))
            .firstMatch
            .waitForExistence(timeout: timeout)

        if let robot = expected.first(where: isShowing) {
            return robot
        }
        throw UnexpectedScreenError(
            expected: expected.map { String(describing: $0) },
            showing: Robots.all.first(where: isShowing).map { String(describing: $0) }
        )
    }

    private func isShowing(_ robot: any Robot.Type) -> Bool {
        descendants(matching: .any)[robot.screenIdentifier].exists
    }
}
