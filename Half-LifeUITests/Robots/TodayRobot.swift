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

/// Drives the Today screen: the greeting, the decay card, the "Today" and "Last cup" tiles, and the one-tap row now,
/// and the other drink-log cards as they're built.
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

    private var curveTimeSpan: XCUIElement {
        app.descendants(matching: .any)[CaffeineDecayViewAccessibilityID.timeSpan]
    }

    private var caffeineToday: XCUIElement {
        app.descendants(matching: .any)[CaffeineIntakeTodayViewAccessibilityID.total]
    }

    private var lastCup: XCUIElement {
        app.descendants(matching: .any)[LastCupViewAccessibilityID.tile]
    }

    /// Checks that the "Last cup" tile shows the cutoff for the usual drink: a time to have it by, or that there's no
    /// more today. Which one depends on the time of day and on the drinks the test has logged.
    func verifyLastCup(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(lastCup.waitForExistence(timeout: 5), "The last cup tile didn't appear.", file: file, line: line)
        let spoken = lastCup.label.lowercased()
        XCTAssertTrue(
            spoken.hasPrefix("last cup") && (spoken.contains("by ") || spoken.contains("no more today"))
                && spoken.contains("your usual"),
            "The last cup tile reads \"\(spoken)\", not a cutoff for the usual drink.",
            file: file,
            line: line
        )
    }

    /// A one-tap favourite's button, looked for only on this screen, because the composer shows the row too.
    private func favouriteButton(_ favourite: OneTapFavourite) -> XCUIElement {
        app.descendants(matching: .any)[Self.screenIdentifier].buttons[favourite.identifier]
    }

    /// The caffeine logged today, in whole milligrams, as the "Today" tile shows it, or `nil` if the tile doesn't
    /// appear. A test passes it back to ``verifyCaffeineLoggedToday(isAbout:file:line:)`` after logging a drink.
    func caffeineLoggedToday(file: StaticString = #filePath, line: UInt = #line) -> Int? {
        XCTAssertTrue(
            caffeineToday.waitForExistence(timeout: 5),
            "The caffeine logged today didn't appear.",
            file: file,
            line: line
        )
        return Self.milligrams(in: caffeineToday.label)
    }

    /// Checks that the "Today" tile shows the caffeine logged today, in milligrams.
    func verifyCaffeineLoggedToday(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            caffeineToday.waitForExistence(timeout: 5),
            "The caffeine logged today didn't appear.",
            file: file,
            line: line
        )
        let spoken = caffeineToday.label.lowercased()
        XCTAssertTrue(
            spoken.hasPrefix("today") && spoken.contains("milligram") && Self.milligrams(in: spoken) != nil,
            "The caffeine logged today reads \"\(spoken)\", not today's amount in milligrams.",
            file: file,
            line: line
        )
    }

    /// Waits for the "Today" tile to show `milligrams`, give or take 1 mg, which allows for each total being rounded
    /// to whole milligrams.
    func verifyCaffeineLoggedToday(isAbout milligrams: Int, file: StaticString = #filePath, line: UInt = #line) {
        let isAbout = NSPredicate { element, _ in
            guard let label = (element as? XCUIElement)?.label, let shown = Self.milligrams(in: label) else {
                return false
            }
            return abs(shown - milligrams) <= 1
        }
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: isAbout, object: caffeineToday)], timeout: 5)
        XCTAssertEqual(
            result,
            .completed,
            "The caffeine logged today reads \"\(caffeineToday.label)\", not about \(milligrams) milligrams.",
            file: file,
            line: line
        )
    }

    /// The caffeine one tap on `favourite` logs, in whole milligrams, as its button says, or `nil` if the button
    /// doesn't appear. A test adds it to ``caffeineLoggedToday(file:line:)`` to know the total after logging it.
    func caffeine(in favourite: OneTapFavourite, file: StaticString = #filePath, line: UInt = #line) -> Int? {
        let button = favouriteButton(favourite)
        XCTAssertTrue(
            button.waitForExistence(timeout: 5), "The \(favourite) one-tap drink isn't showing.", file: file,
            line: line)
        return Self.milligrams(in: button.value as? String ?? "")
    }

    /// Logs a one-tap favourite as consumed now, in one tap.
    func logFavourite(_ favourite: OneTapFavourite, file: StaticString = #filePath, line: UInt = #line) {
        let button = favouriteButton(favourite)
        XCTAssertTrue(
            button.waitForExistence(timeout: 5), "The \(favourite) one-tap drink isn't showing.", file: file,
            line: line)
        button.tap()
    }

    /// Checks that `favourite` says it was just logged. The confirmation lasts 2 seconds, so this polls often rather
    /// than through an expectation, whose polling is too slow to be sure of catching it.
    func verifyFavouriteWasLogged(_ favourite: OneTapFavourite, file: StaticString = #filePath, line: UInt = #line) {
        let button = favouriteButton(favourite)
        let deadline = Date.now.addingTimeInterval(2)
        var spoken = ""
        repeat {
            spoken = "\(button.label) \(button.value as? String ?? "")"
            if spoken.localizedCaseInsensitiveContains("logged") { return }
        } while Date.now < deadline
        XCTFail("The \(favourite) one-tap drink reads \"\(spoken)\", not that it was logged.", file: file, line: line)
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

    /// Checks that the decay curve is labelled with the clock times at its two ends.
    func verifyCurveTimeSpan(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            curveTimeSpan.waitForExistence(timeout: 5),
            "The decay curve's start and end times didn't appear.",
            file: file,
            line: line
        )
        let spoken = curveTimeSpan.label
        XCTAssertEqual(
            spoken.matches(of: #/\d{1,2}:\d{2}/#).count,
            2,
            "The decay curve's times read \"\(spoken)\", not a start and an end time.",
            file: file,
            line: line
        )
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

    /// Checks that the greeting names the user, as onboarding saved it.
    func verifyGreeting(names name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(greeting.waitForExistence(timeout: 5), "The greeting didn't appear.", file: file, line: line)
        XCTAssertTrue(
            greeting.label.localizedCaseInsensitiveContains(name),
            "The greeting reads \"\(greeting.label)\", without \(name).",
            file: file,
            line: line
        )
    }

    /// The whole milligrams in a spoken amount such as "Today, 1,192 milligrams": its digits, ignoring grouping
    /// separators. `nil` if it has no digits.
    private static func milligrams(in label: String) -> Int? {
        Int(label.filter(\.isNumber))
    }
}

extension XCUIElement {
    /// Whether VoiceOver announces the element as a heading.
    fileprivate var isHeader: Bool {
        (value(forKey: "traits") as? UInt64).map { $0 & UIAccessibilityTraits.header.rawValue != 0 } ?? false
    }
}
