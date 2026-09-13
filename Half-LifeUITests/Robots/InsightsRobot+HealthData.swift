//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests InsightsRobot+HealthData
//

import XCTest

extension InsightsRobot {
    /// A kind of Health data with a button on the Insights tab.
    enum HealthData: CaseIterable {
        case sleep, steps, restingHeartRate

        /// The button's identifier.
        var identifier: String {
            switch self {
            case .sleep: InsightsViewAccessibilityID.healthDataSleepButton
            case .steps: InsightsViewAccessibilityID.healthDataStepsButton
            case .restingHeartRate: InsightsViewAccessibilityID.healthDataRestingHeartRateButton
            }
        }
    }

    private var healthDataCard: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.healthDataCard]
    }
    private var weekCard: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.weekCard] }
    private var scrollingContent: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.content]
    }

    private func button(_ kind: HealthData) -> XCUIElement {
        app.buttons[kind.identifier]
    }

    /// Opens the screen for `kind` with its button.
    func openHealthData(_ kind: HealthData, file: StaticString = #filePath, line: UInt = #line) {
        reveal(button(kind), on: scrollingContent, "The \(kind) button", file: file, line: line)
        button(kind).tap()
    }

    /// Checks that the Health data card has a button for each of `kinds`, and none for the others.
    func verifyHealthDataButtons(_ kinds: [HealthData], file: StaticString = #filePath, line: UInt = #line) {
        for kind in kinds {
            reveal(button(kind), on: scrollingContent, "The \(kind) button", file: file, line: line)
        }
        for kind in HealthData.allCases where !kinds.contains(kind) {
            XCTAssertFalse(
                button(kind).exists, "The card has a \(kind) button, with no data for it.", file: file, line: line)
        }
    }

    /// Checks that the tab has no Health data card, once the last 7 days card has loaded.
    func verifyNoHealthDataCard(file: StaticString = #filePath, line: UInt = #line) {
        reveal(weekCard, on: scrollingContent, "The last 7 days card", file: file, line: line)
        XCTAssertFalse(
            healthDataCard.exists, "The Health data card shows, with no Health data.", file: file, line: line)
    }
}
