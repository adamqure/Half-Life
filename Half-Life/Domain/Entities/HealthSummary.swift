//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthSummary
//

import Foundation

/// Today's Apple Health data, as the Today screen's Apple Health card shows it.
///
/// Every metric is optional, because Health can hold any of them, all of them, or none, and HealthKit doesn't reveal
/// whether read access was denied. ``HealthDataRepository`` publishes it. The Apple Health Card article lists its
/// requirement, HSUM-1.
struct HealthSummary: Sendable, Equatable {
    /// A summary with no metrics, from the live data.
    static let empty = HealthSummary()

    /// Last night's sleep, or `nil` if Health has no sleep or time in bed for it.
    let lastNight: LastNightSleep?
    /// Today's steps so far, or `nil` if Health has none. It's `0` only when Health recorded zero.
    let stepsToday: Int?
    /// Today's average resting heart rate, in beats per minute, or `nil` if Health has none yet.
    let restingHeartRateToday: Double?
    /// Whether the values came from the demo data sources rather than Apple Health.
    let isDemo: Bool

    /// Creates a summary.
    ///
    /// - Parameters:
    ///   - lastNight: Last night's sleep, if Health has any.
    ///   - stepsToday: Today's steps so far, if Health has any.
    ///   - restingHeartRateToday: Today's average resting heart rate, in beats per minute, if Health has one.
    ///   - isDemo: Whether the values came from the demo data sources.
    init(
        lastNight: LastNightSleep? = nil, stepsToday: Int? = nil, restingHeartRateToday: Double? = nil,
        isDemo: Bool = false
    ) {
        self.lastNight = lastNight
        self.stepsToday = stepsToday
        self.restingHeartRateToday = restingHeartRateToday
        self.isDemo = isDemo
    }

    /// Whether the summary has no metric at all, so the card is hidden.
    var isEmpty: Bool {
        lastNight == nil && stepsToday == nil && restingHeartRateToday == nil
    }
}
