//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataKindPresentation
//

import SwiftUI

extension HealthDataKind {
    /// The kind's name, such as "Sleep".
    var title: LocalizedStringResource {
        switch self {
        case .sleep: "Sleep"
        case .steps: "Steps"
        case .restingHeartRate: "Resting heart rate"
        }
    }

    /// The kind's SF Symbol, the one the Today screen's Apple Health card uses.
    var symbolName: String {
        switch self {
        case .sleep: "bed.double.fill"
        case .steps: "figure.walk"
        case .restingHeartRate: "heart.fill"
        }
    }

    /// The kind's data color, for its symbol.
    var color: Color {
        switch self {
        case .sleep: .dataSleep
        case .steps: .dataActivity
        case .restingHeartRate: .dataHeart
        }
    }

    /// The kind's light data color, for the tile behind its symbol.
    var subtleColor: Color {
        switch self {
        case .sleep: .dataSleepSubtle
        case .steps: .dataActivitySubtle
        case .restingHeartRate: .dataHeartSubtle
        }
    }

    /// The identifier of the kind's button on the Health data card.
    var buttonIdentifier: String {
        switch self {
        case .sleep: InsightsViewAccessibilityID.healthDataSleepButton
        case .steps: InsightsViewAccessibilityID.healthDataStepsButton
        case .restingHeartRate: InsightsViewAccessibilityID.healthDataRestingHeartRateButton
        }
    }
}
