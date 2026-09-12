//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests TodayRobot
//

import XCTest

/// Drives the Today screen: the greeting now, and the decay card and the drink-log cards as they're built.
struct TodayRobot: Robot {
    /// The Today screen's identifier.
    static let screenIdentifier = TodayViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var greeting: XCUIElement {
        app.descendants(matching: .any)[DailyGreetingViewAccessibilityID.header]
    }

    private var caffeineLevel: XCUIElement {
        app.descendants(matching: .any)[CaffeineDecayViewAccessibilityID.level]
    }

    private var curve: XCUIElement {
        app.descendants(matching: .any)[CaffeineDecayViewAccessibilityID.curve]
    }

    /// Checks that the decay card shows the caffeine in your system now, in milligrams, and its curve.
    func verifyCaffeineInYourSystem(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            caffeineLevel.waitForExistence(timeout: 5),
            "The caffeine in your system didn't appear.",
            file: file,
            line: line
        )
        let spoken = "\(caffeineLevel.label) \(caffeineLevel.value as? String ?? "")".lowercased()
        XCTAssertTrue(
            spoken.contains("milligram"),
            "The caffeine in your system reads \"\(spoken)\", with no amount in milligrams.",
            file: file,
            line: line
        )
        XCTAssertTrue(curve.waitForExistence(timeout: 5), "The decay curve didn't appear.", file: file, line: line)
    }

    /// Checks that the greeting is for a time of day, and that it's the screen's heading.
    func verifyGreetingForTheTimeOfDay(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(greeting.waitForExistence(timeout: 5), "The greeting didn't appear.", file: file, line: line)
        // The eyebrow is set uppercase, so compare without case.
        let label = greeting.label.lowercased()
        let greetings = ["good morning", "good afternoon", "good evening"]
        XCTAssertTrue(
            greetings.contains { label.hasPrefix($0) },
            "The greeting reads \"\(label)\", which isn't for a time of day.",
            file: file,
            line: line
        )
        XCTAssertTrue(
            greeting.isHeader,
            "The greeting isn't marked as the screen's heading.",
            file: file,
            line: line
        )
    }
}

extension XCUIElement {
    /// Whether VoiceOver announces the element as a heading.
    fileprivate var isHeader: Bool {
        (value(forKey: "traits") as? UInt64).map { $0 & UIAccessibilityTraits.header.rawValue != 0 } ?? false
    }
}
