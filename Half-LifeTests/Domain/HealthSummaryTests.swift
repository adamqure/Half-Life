//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthSummaryTests
//

import Testing

@testable import Half_Life

/// Checks when a Health summary is empty, so the Apple Health card is hidden (HSUM-1 in the Apple Health Card
/// article).
struct HealthSummaryTests {

    /// HSUM-1: a summary is empty exactly when it has no metric. A step count of zero isn't empty.
    @Test func aSummaryIsEmptyExactlyWhenItHasNoMetric() {
        #expect(HealthSummary.empty.isEmpty)
        #expect(HealthSummary(isDemo: true).isEmpty)
        #expect(!HealthSummary(lastNight: .inBedOnly(seconds: 3 * 3_600)).isEmpty)
        #expect(!HealthSummary(stepsToday: 0).isEmpty)
        #expect(!HealthSummary(restingHeartRateToday: 58).isEmpty)
    }
}
