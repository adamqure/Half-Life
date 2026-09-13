//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataKind
//

import Foundation

/// A kind of Health data the app reads from Apple Health: the Insights tab's Health data buttons, one per kind.
///
/// ``HealthDataAvailabilityRule`` finds which kinds have data. Its cases are in the order the buttons show. See the
/// Insights article.
enum HealthDataKind: Sendable, Hashable, CaseIterable {
    /// Sleep: its stages, from any tracker.
    case sleep
    /// The day's step count.
    case steps
    /// The day's resting heart rate.
    case restingHeartRate
}
