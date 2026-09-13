//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests RestingHeartRateComparisonRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the resting heart rate comparison against RHRCOMP-1 to RHRCOMP-7 in the Insights article. The rule is pure,
/// so its tests need no fakes.
///
/// Each test describes its days as pairs: the caffeine one night, at its recorded sleep onset, and the resting heart
/// rate the day after it. Pair `i`'s night is on day `i`, and its heart rate on day `i + 1`.
struct RestingHeartRateComparisonRuleTests {

    let rule = RestingHeartRateComparisonRule()

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midnight at the start of day `index`.
    static func day(_ index: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: Double(index) * 86_400)
    }

    /// The nights and heart rates for `pairs`: each night's caffeine at sleep onset, and the heart rate the day after.
    static func histories(
        _ pairs: [(milligrams: Double, beatsPerMinute: Double?)], threshold: SleepThreshold = .standard,
        isDemo: Bool = false
    ) -> (nights: CaffeineNightHistory, heartRates: RestingHeartRateHistory) {
        let nights = pairs.enumerated().map { index, pair in
            CaffeineNight(
                day: day(index), moment: day(index).addingTimeInterval(23 * 3_600), measuredAt: .sleepOnset,
                milligrams: pair.milligrams, isCaffeineNight: pair.milligrams > threshold.milligrams)
        }
        let days = pairs.enumerated().map { index, pair in
            RestingHeartRateDay(day: day(index + 1), beatsPerMinute: pair.beatsPerMinute)
        }
        return (
            CaffeineNightHistory(nights: nights, threshold: threshold, isDemo: false),
            RestingHeartRateHistory(days: days, isDemo: isDemo)
        )
    }

    /// Five days after 80 mg at sleep onset, then five after 10 mg, with the given heart rates.
    static func pairs(after: [Double], other: [Double]) -> [(
        milligrams: Double, beatsPerMinute: Double?
    )] {
        after.map { (80, $0) } + other.map { (10, $0) }
    }

    func comparison(
        _ pairs: [(milligrams: Double, beatsPerMinute: Double?)], threshold: SleepThreshold = .standard,
        isDemo: Bool = false
    ) -> RestingHeartRateComparison {
        let (nights, heartRates) = Self.histories(pairs, threshold: threshold, isDemo: isDemo)
        return rule.comparison(of: heartRates, with: nights, calendar: Self.utc)
    }

    // MARK: - RHRCOMP-1: each day with a reading pairs with the night before it

    /// A day follows a caffeine night when the night before it is one, over the threshold. At the threshold, it isn't.
    @Test func eachDayPairsWithTheNightBeforeItOverTheThreshold() {
        let result = comparison([(41, 62), (40, 58), (0, 57)])

        #expect(
            result.days == [
                RestingHeartRateComparison.Day(
                    day: Self.day(1), beatsPerMinute: 62, followsCaffeine: true, measuredAt: .sleepOnset),
                RestingHeartRateComparison.Day(
                    day: Self.day(2), beatsPerMinute: 58, followsCaffeine: false, measuredAt: .sleepOnset),
                RestingHeartRateComparison.Day(
                    day: Self.day(3), beatsPerMinute: 57, followsCaffeine: false, measuredAt: .sleepOnset),
            ])
    }

    @Test func aDayWithNoReadingIsLeftOut() {
        #expect(
            comparison([(80, 62), (80, nil), (0, 57)]).days.map(\.day) == [Self.day(1), Self.day(3)])
    }

    /// A reading on a day whose night before isn't in the history, such as the first day, is left out.
    @Test func aDayWithNoNightBeforeItIsLeftOut() {
        var (nights, heartRates) = Self.histories([(80, 62), (0, 57)])
        heartRates = RestingHeartRateHistory(
            days: [RestingHeartRateDay(day: Self.day(0), beatsPerMinute: 70)] + heartRates.days,
            isDemo: false)

        let result = rule.comparison(of: heartRates, with: nights, calendar: Self.utc)

        #expect(result.days.map(\.day) == [Self.day(1), Self.day(2)])
    }

    /// The threshold is the one the nights were judged against.
    @Test func usesTheNightsThreshold() throws {
        let threshold = try #require(SleepThreshold(milligrams: 25))

        let result = comparison([(30, 62), (20, 57)], threshold: threshold)

        #expect(result.days.map(\.followsCaffeine) == [true, false])
        #expect(result.threshold == threshold)
    }

    /// A night Health recorded no sleep for is measured at the bedtime, and counts the same way. The day says so.
    @Test func aNightMeasuredAtBedtimeCountsTheSameWay() {
        var (nights, heartRates) = Self.histories([(80, 62), (10, 57)])
        nights = CaffeineNightHistory(
            nights: [
                CaffeineNight(
                    day: Self.day(0), moment: Self.day(0).addingTimeInterval(81_000), measuredAt: .bedtime,
                    milligrams: 80, isCaffeineNight: true),
                nights.nights[1],
            ],
            threshold: .standard, isDemo: false)

        let result = rule.comparison(of: heartRates, with: nights, calendar: Self.utc)

        #expect(result.days.map(\.followsCaffeine) == [true, false])
        #expect(result.days.map(\.measuredAt) == [.bedtime, .sleepOnset])
    }

    // MARK: - RHRCOMP-2: each group's day count and average

    @Test func eachGroupHasItsDayCountAndAverage() {
        let result = comparison([(80, 60), (90, 64), (10, 57), (0, 58), (20, 56)])

        #expect(
            result.afterCaffeine
                == RestingHeartRateComparison.Group(dayCount: 2, averageBeatsPerMinute: 62))
        #expect(
            result.otherDays == RestingHeartRateComparison.Group(dayCount: 3, averageBeatsPerMinute: 57))
        #expect(result.difference == 5)
    }

    @Test func anEmptyGroupHasNoAverageAndThereIsNoDifference() {
        let result = comparison([(10, 57), (0, 58)])

        #expect(
            result.afterCaffeine
                == RestingHeartRateComparison.Group(dayCount: 0, averageBeatsPerMinute: nil))
        #expect(result.difference == nil)
    }

    // MARK: - RHRCOMP-3: with fewer than 5 days in either group, there aren't enough days

    @Test func fewerThanFiveDaysInAGroupIsNotEnough() {
        let fourAfter = comparison(
            Self.pairs(after: [62, 63, 64, 65], other: [57, 57, 57, 57, 57, 57]))
        let fourOther = comparison(Self.pairs(after: [62, 63, 64, 65, 66], other: [57, 57, 57, 57]))

        #expect(fourAfter.finding == .notEnoughDays)
        #expect(fourOther.finding == .notEnoughDays)
        #expect(fourAfter.afterCaffeine.dayCount == 4)
        #expect(RestingHeartRateComparisonRule.minimumDays == 5)
    }

    // MARK: - RHRCOMP-4: a difference more than twice its standard error, and at least 1 bpm, is a pattern

    /// The averages are 61 and 57.2, with sample variances 2.5 and 0.7, so the standard error is 0.8 and the 3.8 bpm
    /// difference is more than twice it.
    @Test func aDifferenceBeyondTwiceItsStandardErrorIsAPattern() {
        let result = comparison(Self.pairs(after: [60, 62, 61, 63, 59], other: [57, 58, 56, 58, 57]))

        #expect(result.finding == .pattern)
    }

    /// A lower heart rate after caffeine at bedtime is a pattern too. The rule never assumes a direction.
    @Test func aLowerHeartRateAfterCaffeineIsAPatternToo() {
        let result = comparison(Self.pairs(after: [56, 57, 56, 57, 56], other: [60, 61, 60, 61, 60]))

        #expect(result.finding == .pattern)
        #expect((result.difference ?? 0) < 0)
    }

    /// With no spread at all, any difference of at least 1 bpm is a pattern.
    @Test func withNoSpreadADifferenceOfOneIsAPattern() {
        let result = comparison(Self.pairs(after: [61, 61, 61, 61, 61], other: [60, 60, 60, 60, 60]))

        #expect(result.finding == .pattern)
    }

    // MARK: - RHRCOMP-5: a difference within twice its standard error isn't clear

    /// The averages are 60 and 58, with sample variances 14.5 and 2.5, so the standard error is about 1.84, and the 2
    /// bpm difference is less than twice it.
    @Test func aDifferenceWithinTwiceItsStandardErrorIsNotClear() {
        let result = comparison(Self.pairs(after: [55, 65, 58, 62, 60], other: [58, 59, 57, 60, 56]))

        #expect(result.finding == .noClearDifference)
        #expect(result.difference == 2)
    }

    // MARK: - RHRCOMP-6: a difference under 1 bpm isn't clear, however consistent

    @Test func aDifferenceUnderOneBeatIsNotClear() {
        let result = comparison(
            Self.pairs(after: [60.5, 60.5, 60.5, 60.5, 60.5], other: [60, 60, 60, 60, 60]))

        #expect(result.finding == .noClearDifference)
        #expect(RestingHeartRateComparisonRule.minimumDifference == 1)
    }

    // MARK: - RHRCOMP-7: whether the heart rates are the demo's is carried

    @Test func carriesWhetherTheHeartRatesAreTheDemos() {
        #expect(comparison([(80, 60)], isDemo: true).isDemo)
        #expect(!comparison([(80, 60)]).isDemo)
    }
}
