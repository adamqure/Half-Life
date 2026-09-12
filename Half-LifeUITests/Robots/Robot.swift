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

    /// Waits for `element`, failing at the test's call site if it doesn't appear.
    func require(_ element: XCUIElement, _ description: String, file: StaticString, line: UInt) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(description) didn't appear.", file: file, line: line)
    }

    /// Waits up to 5 seconds for `element`'s label to satisfy `matches`, and returns whether it did.
    func waitForLabel(of element: XCUIElement, _ matches: @escaping (String) -> Bool) -> Bool {
        let predicate = NSPredicate { object, _ in
            guard let label = (object as? XCUIElement)?.label else { return false }
            return matches(label)
        }
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 5)
            == .completed
    }

    /// Swipes `scrollView` sideways, then checks that all of its content sits between its left and right edges, so
    /// the screen scrolls only vertically.
    ///
    /// The swipe starts in the screen's right margin, where nothing can be tapped, so it can't press a button that
    /// spans the width, such as Welcome's Get started at the largest text sizes. It waits up to 5 seconds for the
    /// content to settle, so a push animation or a bounce back doesn't fail it.
    func verifyScrollsOnlyVertically(_ scrollView: XCUIElement, file: StaticString, line: UInt) {
        require(scrollView, "The scrolling content", file: file, line: line)
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
        let fits = NSPredicate { object, _ in
            guard let element = object as? XCUIElement else { return false }
            return Self.elementsOutsideItsWidth(element).isEmpty
        }
        let result = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: fits, object: scrollView)], timeout: 5)
        XCTAssertEqual(
            result, .completed,
            "The content is wider than the screen, or scrolled sideways: "
                + Self.elementsOutsideItsWidth(scrollView).joined(separator: "; "),
            file: file,
            line: line
        )
    }

    /// Describes each element in `scrollView` that extends past its left or right edge.
    private static func elementsOutsideItsWidth(_ scrollView: XCUIElement) -> [String] {
        let snapshot: any XCUIElementSnapshot
        do {
            snapshot = try scrollView.snapshot()
        } catch {
            return ["the content couldn't be read (\(error))"]
        }
        let bounds = snapshot.frame
        // Only elements with a label count, because they're what the user reads or uses. iOS's own decorations, such
        // as the dimming it draws under the navigation bar, are wider than the screen and have no label.
        return descendants(of: snapshot)
            .filter { !$0.label.isEmpty && !$0.frame.isEmpty }
            .filter { $0.frame.minX < bounds.minX - 0.5 || $0.frame.maxX > bounds.maxX + 0.5 }
            .map { "\($0.elementType.rawValue) \"\($0.identifier)\" \"\($0.label)\" at \($0.frame) in \(bounds)" }
    }

    private static func descendants(of snapshot: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        snapshot.children.flatMap { [$0] + descendants(of: $0) }
    }
}

@MainActor
extension XCUIApplication {
    /// Launches the app with a profile that has finished onboarding, so it opens on the Today screen.
    ///
    /// The app keeps the profile in a temporary file and simulates every permission, so the test never touches the
    /// simulator's own profile or a system prompt. See the Onboarding article's "UI tests".
    func launchPastOnboarding() {
        launch(profile: LaunchEnvironmentKey.completed)
    }

    /// Launches the app with nothing saved, so it opens on onboarding's Welcome screen.
    func launchAtOnboarding() {
        launch(profile: LaunchEnvironmentKey.fresh)
    }

    /// Launches the app at onboarding's Welcome screen, with text at the largest accessibility size.
    func launchAtOnboardingWithTheLargestText() {
        launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        launchAtOnboarding()
    }

    private func launch(profile: String) {
        launchEnvironment[LaunchEnvironmentKey.profile] = profile
        launch()
    }
}

/// Every robot in the suite. Resolution uses it to name the screen that's showing when a test's expectation fails.
///
/// Add each new robot here.
enum Robots {
    /// All robots, one per screen.
    static let all: [any Robot.Type] = [
        AppRobot.self, DrinkComposerRobot.self, TodayRobot.self, WelcomeRobot.self, AboutYouRobot.self,
        HalfLifeFactorsRobot.self, BedtimeRobot.self, PermissionsRobot.self, OnboardingSummaryRobot.self,
    ]
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
