//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests RobotResolutionUITests
//

import XCTest

/// Constitution Article II.11: a test resolves which expected robot is on screen, or fails naming what's showing.
final class RobotResolutionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testResolvingAmongSeveralRobotsReturnsTheOneShowing() throws {
        let app = XCUIApplication()
        app.launch()

        let robot = try app.resolve(expecting: [AbsentRobot.self, AppRobot.self])

        XCTAssertTrue(robot is AppRobot)
    }

    @MainActor
    func testResolvingARobotThatIsNotShowingFailsAndNamesTheScreenShowing() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertThrowsError(try app.resolve(AbsentRobot.self, timeout: 1)) { error in
            XCTAssertEqual(
                error as? UnexpectedScreenError,
                UnexpectedScreenError(expected: ["AbsentRobot"], showing: "AppRobot")
            )
        }
    }
}

/// A test double for a screen the app never shows.
private struct AbsentRobot: Robot {
    // A literal on purpose: no view defines this identifier.
    static let screenIdentifier = "robotResolutionUITests.absent"

    let app: XCUIApplication
}
