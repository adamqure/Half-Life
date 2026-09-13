//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoSleepToleranceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that the demo's drinks and nights give the Sleep screen something to show, so a reviewer sees the tolerance
/// move the cutoff (DEMOTOL-1 in the Insights article).
struct DemoSleepToleranceTests {

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Noon on 15 June 2026, in UTC.
    static let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)) ?? .distantPast

    // MARK: - DEMOTOL-1: the demo shows a tolerance, and both comparisons

    @Test func theDemoShowsAToleranceAndBothComparisons() throws {
        let rule = SleepToleranceRule()
        let range = try #require(rule.range(endingAt: Self.now, calendar: Self.utc))
        let intervals = DemoHealthScript().sleepIntervals(in: range, now: Self.now, calendar: Self.utc)
        let drinks = DemoHistoryRule().drinks(now: Self.now, calendar: Self.utc)
        let inputs = SleepToleranceRule.Inputs(
            intervals: intervals, intakes: drinks.map(\.intake), kinetics: .standard, isDemo: true)

        let analysis = try #require(rule.analysis(inputs, now: Self.now, calendar: Self.utc))

        #expect(analysis.tolerance != nil)
        #expect(analysis.timeAsleep != nil)
        #expect(analysis.timeToFallAsleep != nil)
    }
}
