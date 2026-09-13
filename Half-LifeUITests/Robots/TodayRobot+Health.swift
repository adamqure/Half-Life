//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests TodayRobot+Health
//

import XCTest

/// Drives the Today screen's Apple Health card. It's part of `TodayRobot`, because the card is part of the Today
/// screen. The elements stay private to the robot (constitution Article II.8).
extension TodayRobot {
    /// A metric the Apple Health card can show.
    enum HealthMetric: CaseIterable {
        case lastNight, inBed, steps, restingHeartRate

        fileprivate var identifier: String {
            switch self {
            case .lastNight: HealthSummaryViewAccessibilityID.lastNight
            case .inBed: HealthSummaryViewAccessibilityID.inBed
            case .steps: HealthSummaryViewAccessibilityID.steps
            case .restingHeartRate: HealthSummaryViewAccessibilityID.restingHeartRate
            }
        }
    }

    private var healthTitle: XCUIElement {
        app.descendants(matching: .any)[HealthSummaryViewAccessibilityID.title]
    }

    private var healthCard: XCUIElement {
        app.descendants(matching: .any)[HealthSummaryViewAccessibilityID.card]
    }

    /// The root screen's log button, which sits above the tab bar. Only its frame is read, to tell where the bar
    /// starts.
    private var barTop: CGFloat {
        app.buttons[AppViewAccessibilityID.logButton].frame.minY
    }

    private func healthCell(_ metric: HealthMetric) -> XCUIElement {
        app.descendants(matching: .any)[metric.identifier]
    }

    /// Scrolls to the end of the Today screen, where the Apple Health card sits above the log button and the tab bar.
    func showHealthCard(file: StaticString = #filePath, line: UInt = #line) {
        require(healthCard, "The Apple Health card", file: file, line: line)
        var previousFrame = CGRect.null
        var swipes = 0
        while healthCard.frame != previousFrame && swipes < 10 {
            previousFrame = healthCard.frame
            app.swipeUp()
            swipes += 1
        }
        XCTAssertLessThanOrEqual(
            healthCard.frame.maxY, barTop, "The Apple Health card never came fully above the tab bar.", file: file,
            line: line)
    }

    /// Checks that the Apple Health card, the Today screen's last card, sits wholly above the tab bar's fade over the
    /// log button, so none of it is hidden or dimmed. Call it after ``showHealthCard(file:line:)``, which scrolls to
    /// the end.
    func verifyHealthCardClearsTheLogButton(file: StaticString = #filePath, line: UInt = #line) {
        require(healthCard, "The Apple Health card", file: file, line: line)
        let cardBottom = healthCard.frame.maxY
        let fadeTop = barTop - tabBarFadeHeight
        XCTAssertLessThanOrEqual(
            cardBottom, fadeTop,
            "Scrolled to the end, the Apple Health card ends at y \(cardBottom), inside the fade that starts at "
                + "y \(fadeTop), above the log button at y \(barTop).", file: file, line: line)
    }

    /// Checks that the Today screen has no Apple Health card, and no heading for it, once the screen has loaded.
    func verifyHealthCardIsHidden(file: StaticString = #filePath, line: UInt = #line) {
        verifyCaffeineLoggedToday(file: file, line: line)
        XCTAssertTrue(
            healthCard.waitForNonExistence(timeout: 5), "The Apple Health card is showing.", file: file, line: line)
        XCTAssertFalse(healthTitle.exists, "The Apple Health card's heading is showing.", file: file, line: line)
    }

    /// Checks that the Apple Health card shows exactly `metrics`, under a heading that says whether its data is Apple
    /// Health's or the demo's.
    func verifyHealthCard(
        shows metrics: Set<HealthMetric>, isDemo: Bool = false, file: StaticString = #filePath, line: UInt = #line
    ) {
        require(healthCard, "The Apple Health card", file: file, line: line)
        let heading = isDemo ? "demo health data" : "from apple health"
        XCTAssertTrue(
            waitForLabel(of: healthTitle) { $0.lowercased() == heading },
            "The Apple Health card's heading reads \"\(healthTitle.label)\", not \"\(heading)\".", file: file,
            line: line)
        for metric in HealthMetric.allCases {
            XCTAssertEqual(
                healthCell(metric).exists, metrics.contains(metric),
                "The Apple Health card \(metrics.contains(metric) ? "doesn't show" : "shows") \(metric).", file: file,
                line: line)
        }
    }

    /// Checks that the card shows demo data: its heading says so, and it shows last night's demo sleep. The demo's
    /// steps and resting heart rate depend on the time of day, so they aren't checked.
    func verifyHealthCardShowsDemoData(file: StaticString = #filePath, line: UInt = #line) {
        require(healthCard, "The Apple Health card", file: file, line: line)
        XCTAssertTrue(
            waitForLabel(of: healthTitle) { $0.lowercased() == "demo health data" },
            "The Apple Health card's heading reads \"\(healthTitle.label)\", not that its data is the demo's.",
            file: file, line: line)
        XCTAssertTrue(
            healthCell(.lastNight).waitForExistence(timeout: 5), "The demo card doesn't show last night's sleep.",
            file: file, line: line)
    }

    /// Checks that the card's time in bed says it isn't sleep, so the card never passes it off as sleep.
    func verifyTimeInBedSaysItIsNotSleep(file: StaticString = #filePath, line: UInt = #line) {
        let inBed = healthCell(.inBed)
        require(inBed, "The time in bed", file: file, line: line)
        XCTAssertTrue(
            inBed.label.localizedCaseInsensitiveContains("not sleep"),
            "The time in bed reads \"\(inBed.label)\", which doesn't say it isn't sleep.", file: file, line: line)
    }
}
