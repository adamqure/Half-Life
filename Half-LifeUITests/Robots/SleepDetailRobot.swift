//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests SleepDetailRobot
//

import XCTest

/// Drives `SleepDetailView`, the Insights tab's Sleep screen: time asleep, and the time to fall asleep, against the
/// caffeine at sleep onset.
struct SleepDetailRobot: Robot {
    /// The screen's identifier.
    static let screenIdentifier = SleepDetailViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { element(SleepDetailViewAccessibilityID.screen) }
    private var title: XCUIElement { element(SleepDetailViewAccessibilityID.title) }
    private var finding: XCUIElement { element(SleepDetailViewAccessibilityID.finding) }
    private var timeAsleepChart: XCUIElement { element(SleepDetailViewAccessibilityID.timeAsleepChart) }
    private var fallingAsleepNote: XCUIElement { element(SleepDetailViewAccessibilityID.fallingAsleepNote) }
    private var source: XCUIElement { element(SleepDetailViewAccessibilityID.source) }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// Checks that the screen's title is `title`, such as "Sleep".
    func verifyTitle(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        require(self.title, "The screen's title", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: self.title) { $0 == title }, "The screen is \"\(self.title.label)\", not \(title).",
            file: file, line: line)
    }

    /// Checks that what the nights say about time asleep begins with `text`, such as "Not enough nights to say yet".
    func verifyFinding(startingWith text: String, file: StaticString = #filePath, line: UInt = #line) {
        require(finding, "What the nights say about time asleep", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: finding) { $0.hasPrefix(text) }, "The finding is \"\(finding.label)\", not \(text).",
            file: file, line: line)
    }

    /// Checks that there's no time asleep chart, because there are no nights to draw.
    func verifyNoNightsCharted(file: StaticString = #filePath, line: UInt = #line) {
        require(finding, "What the nights say about time asleep", file: file, line: line)
        XCTAssertFalse(timeAsleepChart.exists, "The time asleep chart shows, with no nights.", file: file, line: line)
    }

    /// Checks that the time to fall asleep card says why it can't compare, and that the sleep comes from `origin`, such
    /// as "Sleep from Apple Health".
    func verifyFallingAsleepNoteAndSource(_ origin: String, file: StaticString = #filePath, line: UInt = #line) {
        reveal(fallingAsleepNote, on: screen, "The time to fall asleep note", file: file, line: line)
        reveal(source, on: screen, "Where the sleep comes from", file: file, line: line)
        XCTAssertEqual(source.label, origin, "The sleep comes from \"\(source.label)\".", file: file, line: line)
    }
}
