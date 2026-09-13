//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StepsComparisonRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the steps comparison against STEPSRULE-1 to STEPSRULE-6 in the Insights article.
///
/// The rule is pure, so its tests need no fakes. The days are in New York, and the first step day is June 1, 2026.
struct StepsComparisonRuleTests {
    let rule = StepsComparisonRule()
    let calendar: Calendar
    /// Midnight at the start of June 1, 2026, in New York.
    let june1: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        self.calendar = calendar
        june1 = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
    }

    /// Midnight `offset` days after June 1.
    func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: june1) ?? june1
    }

    /// Step days from June 1 on, one per value, oldest first.
    func steps(_ values: [Int?], isDemo: Bool = false) -> StepHistory {
        StepHistory(
            days: values.enumerated().map { DailySteps(day: day($0.offset), steps: $0.element) }, isDemo: isDemo)
    }

    /// Step days whose first `after.count` days each follow a caffeine night, and whose next `other.count` don't, with
    /// the caffeine nights that make them so.
    func split(after: [Int], other: [Int]) -> (nights: Set<Date>, steps: StepHistory) {
        // Step day `i` follows a caffeine night when the night of day `i - 1` was one.
        (Set((0..<after.count).map { day($0 - 1) }), steps(after + other))
    }

    func verdict(_ split: (nights: Set<Date>, steps: StepHistory)) -> StepsComparison.Verdict {
        rule.comparison(caffeineNightDays: split.nights, threshold: .standard, steps: split.steps, calendar: calendar)
            .verdict
    }

    // MARK: - STEPSRULE-1: a day follows a caffeine night when the night of the day before it was one

    @Test func aDayFollowsACaffeineNightWhenTheNightBeforeWasOne() {
        let comparison = rule.comparison(
            caffeineNightDays: [day(-1), day(1)], threshold: .standard, steps: steps([8_000, 9_000, 7_000, 6_000]),
            calendar: calendar)

        #expect(comparison.days.map(\.followsCaffeineNight) == [true, false, true, false])
        #expect(comparison.days.map(\.day) == [day(0), day(1), day(2), day(3)])
        #expect(comparison.days.map(\.steps) == [8_000, 9_000, 7_000, 6_000])
    }

    @Test func aNightIsMatchedByItsDayWhateverTheTimeGiven() {
        let eveningOfMay31 = day(-1).addingTimeInterval(22 * 3_600)

        let comparison = rule.comparison(
            caffeineNightDays: [eveningOfMay31], threshold: .standard, steps: steps([8_000]), calendar: calendar)

        #expect(comparison.days.map(\.followsCaffeineNight) == [true])
    }

    // MARK: - STEPSRULE-2: a day with no steps stays in the days, and counts in neither group

    @Test func aDayWithNoStepsCountsInNeitherGroup() {
        let comparison = rule.comparison(
            caffeineNightDays: [day(-1)], threshold: .standard, steps: steps([nil, nil, 5_000]), calendar: calendar)

        #expect(comparison.days.map(\.steps) == [nil, nil, 5_000])
        #expect(comparison.afterCaffeineNight == nil)
        #expect(comparison.otherDays == StepsComparison.Group(averageSteps: 5_000, dayCount: 1))
    }

    // MARK: - STEPSRULE-3: each group has its days' average steps and its day count

    @Test func eachGroupHasItsAverageAndItsDayCount() {
        let (nights, history) = split(after: [6_000, 7_000], other: [9_000, 10_000, 11_000])

        let comparison = rule.comparison(
            caffeineNightDays: nights, threshold: .standard, steps: history, calendar: calendar)

        #expect(comparison.afterCaffeineNight == StepsComparison.Group(averageSteps: 6_500, dayCount: 2))
        #expect(comparison.otherDays == StepsComparison.Group(averageSteps: 10_000, dayCount: 3))
    }

    // MARK: - STEPSRULE-4: with fewer than 5 days in either group, there are too few days to compare

    @Test func withFewerThanFiveDaysInAGroupThereAreTooFewDays() {
        #expect(
            verdict(split(after: [6_000, 6_100, 5_900, 6_000], other: Array(repeating: 9_000, count: 10)))
                == .tooFewDays)
        #expect(
            verdict(split(after: Array(repeating: 6_000, count: 10), other: [9_000, 9_100, 8_900, 9_000]))
                == .tooFewDays)
    }

    // MARK: - STEPSRULE-5: a difference within twice its standard error is no clear difference

    @Test func aDifferenceWithinTwiceItsStandardErrorIsNoClearDifference() {
        // Means 9,000 and 8,700: a 300-step difference against a standard error of about 381.
        #expect(
            verdict(split(after: [8_000, 9_000, 10_000, 8_500, 9_500], other: [8_500, 8_900, 8_300, 9_100, 8_700]))
                == .noClearDifference)
        // The same steps every day, as in the UI tests' simulated Health.
        #expect(
            verdict(split(after: Array(repeating: 8_420, count: 5), other: Array(repeating: 8_420, count: 25)))
                == .noClearDifference)
    }

    // MARK: - STEPSRULE-6: a difference beyond twice its standard error is fewer or more steps after a caffeine night

    @Test func aDifferenceBeyondTwiceItsStandardErrorIsFewerOrMoreSteps() {
        // Means 6,000 and 9,000: a 3,000-step difference against a standard error of 100.
        let low = [6_000, 6_200, 5_800, 6_100, 5_900]
        let high = [9_000, 9_200, 8_800, 9_100, 8_900]

        #expect(verdict(split(after: low, other: high)) == .fewerAfterCaffeineNight(steps: 3_000))
        #expect(verdict(split(after: high, other: low)) == .moreAfterCaffeineNight(steps: 3_000))
        // No spread at all, and a difference, is beyond it.
        #expect(
            verdict(split(after: Array(repeating: 8_000, count: 5), other: Array(repeating: 8_100, count: 5)))
                == .fewerAfterCaffeineNight(steps: 100))
    }

    // MARK: - STEPSRULE-1: the comparison carries the threshold, and whether the steps are the demo's

    @Test func theComparisonCarriesTheThresholdAndWhetherTheStepsAreTheDemos() throws {
        let threshold = try #require(SleepThreshold(milligrams: 55))
        let demo = rule.comparison(
            caffeineNightDays: [], threshold: threshold, steps: steps([8_000], isDemo: true), calendar: calendar)
        let live = rule.comparison(
            caffeineNightDays: [], threshold: .standard, steps: steps([8_000]), calendar: calendar)

        #expect(demo.threshold == threshold)
        #expect(demo.isDemo)
        #expect(!live.isDemo)
    }
}
