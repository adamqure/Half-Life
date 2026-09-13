//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepDetailFallingAsleepTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks how the Sleep screen reads the time to fall asleep (SLEEPSCREEN-5 in the Insights article): longer or
/// shorter only beyond 5 minutes, which the owner chose on 2026-09-13.
struct SleepDetailFallingAsleepTests {

    static func state(underMinutes: Double, overMinutes: Double) -> SleepDetailFeature.State {
        let empty = SleepCaffeineAnalysis.empty()
        let comparison = SleepComparison(
            underSeconds: underMinutes * 60, overSeconds: overMinutes * 60, nightsUnder: 5, nightsOver: 5)
        return SleepDetailFeature.State(
            analysis: SleepCaffeineAnalysis(
                nights: [], tolerance: nil, timeAsleep: nil, timeToFallAsleep: comparison, period: empty.period,
                days: empty.days, isDemo: false))
    }

    // MARK: - SLEEPSCREEN-5: longer or shorter beyond 5 minutes, and unknown without a comparison

    @Test func moreThanFiveMinutesLongerOverTheThresholdIsLonger() {
        #expect(Self.state(underMinutes: 12, overMinutes: 18).fallingAsleep == .longer)
    }

    @Test func moreThanFiveMinutesShorterOverTheThresholdIsShorter() {
        #expect(Self.state(underMinutes: 18, overMinutes: 12).fallingAsleep == .shorter)
    }

    @Test(arguments: [0.0, 5, -5])
    func withinFiveMinutesIsAboutTheSame(difference: Double) {
        #expect(Self.state(underMinutes: 20, overMinutes: 20 + difference).fallingAsleep == .aboutTheSame)
    }

    @Test func withoutAComparisonItsUnknown() {
        #expect(SleepDetailFeature.State().fallingAsleep == .unknown)
        #expect(SleepDetailFeature.State(analysis: .empty()).fallingAsleep == .unknown)
    }
}
