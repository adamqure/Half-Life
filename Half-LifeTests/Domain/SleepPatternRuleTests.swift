//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepPatternRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the step from the Sleep screen's analysis to the finding on the Insights tab's first card, against PATTERN-1
/// to PATTERN-6 in the Insights article. ``SleepToleranceRule`` finds the analysis's nights, and its own tests cover
/// them, so these tests build analyses directly. The rule is pure, so they need no fakes.
struct SleepPatternRuleTests {

    let rule = SleepPatternRule()

    static let period = DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 30 * 24 * 3_600)

    /// A night with `milligrams` in the body at sleep onset. Only its caffeine matters here.
    static func night(_ milligrams: Double) -> SleepCaffeineNight {
        SleepCaffeineNight(
            sleepOnset: period.start, asleepSeconds: 7 * 3_600, secondsToFallAsleep: nil, caffeineAtOnset: milligrams)
    }

    /// Time asleep of `overHours` on `over` nights over the threshold, against `underHours` on `under` nights at or
    /// under it.
    static func timeAsleep(
        over: Int = 6, overHours: Double = 6, under: Int = 12, underHours: Double = 7
    ) -> SleepComparison {
        SleepComparison(
            underSeconds: underHours * 3_600, overSeconds: overHours * 3_600, nightsUnder: under, nightsOver: over)
    }

    /// An analysis of 30 days with `timeAsleep`, and nights to match its counts unless `nights` are given.
    static func analysis(
        timeAsleep: SleepComparison?, nights: [SleepCaffeineNight]? = nil, tolerance: SleepTolerance? = nil
    ) -> SleepCaffeineAnalysis {
        let matching = timeAsleep.map {
            Array(repeating: night(175), count: $0.nightsOver) + Array(repeating: night(0), count: $0.nightsUnder)
        }
        return SleepCaffeineAnalysis(
            nights: nights ?? matching ?? [], tolerance: tolerance, timeAsleep: timeAsleep, timeToFallAsleep: nil,
            period: period, days: 30, isDemo: false)
    }

    // MARK: - PATTERN-1: the nights are grouped as the analysis grouped them for time asleep

    @Test func theNightsAreTheAnalysissGroups() {
        let pattern = rule.pattern(from: Self.analysis(timeAsleep: Self.timeAsleep(over: 6, under: 12)))

        #expect(pattern.nightsOver == 6)
        #expect(pattern.nightsUnder == 12)
    }

    /// Without a comparison, a side has fewer than 5 nights. They're counted by their caffeine at onset, a night at the
    /// threshold counting as under it, and they're too few to say anything.
    @Test func withoutAComparisonTheNightsAreCountedAndTooFew() {
        let nights = [Self.night(41), Self.night(40), Self.night(10)]
        let pattern = rule.pattern(from: Self.analysis(timeAsleep: nil, nights: nights))

        #expect(pattern.nightsOver == 1)
        #expect(pattern.nightsUnder == 2)
        #expect(pattern.direction == .aboutTheSame)
        #expect(pattern.confidence == .tooFew)
    }

    // MARK: - PATTERN-2: the direction, with averages less than 15 minutes apart about the same

    /// Hours asleep on the nights over the threshold, against 7 on the others, and the direction they show.
    static let directions: [(Double, SleepPattern.Direction)] = [
        (6, .shorter), (8, .longer), (7 - 14.0 / 60, .aboutTheSame), (7 - 15.0 / 60, .shorter),
        (7 + 15.0 / 60, .longer),
    ]

    @Test(arguments: SleepPatternRuleTests.directions)
    func theNightsOverTheThresholdCanBeShorterLongerOrAboutTheSame(
        overHours: Double, direction: SleepPattern.Direction
    ) {
        let analysis = Self.analysis(timeAsleep: Self.timeAsleep(overHours: overHours, underHours: 7))

        #expect(rule.pattern(from: analysis).direction == direction)
    }

    // MARK: - PATTERN-3: the confidence comes from the smaller group, on either side

    @Test(arguments: zip([5, 9, 10], [SleepPattern.Confidence.earlySign, .earlySign, .consistent]))
    func theConfidenceComesFromTheSmallerGroup(smaller: Int, confidence: SleepPattern.Confidence) {
        let fewerOver = Self.analysis(timeAsleep: Self.timeAsleep(over: smaller, under: 12))
        let fewerUnder = Self.analysis(timeAsleep: Self.timeAsleep(over: 12, under: smaller))

        #expect(rule.pattern(from: fewerOver).confidence == confidence)
        #expect(rule.pattern(from: fewerUnder).confidence == confidence)
    }

    // MARK: - PATTERN-4: the threshold is the analysis's

    @Test func theThresholdIsTheToleranceOrTheStandardWithoutOne() throws {
        let tolerance = SleepTolerance(milligrams: 55, nightsUnder: 12, nightsOver: 6)
        let learned = rule.pattern(from: Self.analysis(timeAsleep: Self.timeAsleep(), tolerance: tolerance))
        let standard = rule.pattern(from: Self.analysis(timeAsleep: Self.timeAsleep()))

        #expect(learned.threshold == (try #require(SleepThreshold(milligrams: 55))))
        #expect(standard.threshold == .standard)
    }

    // MARK: - PATTERN-5: the days without a counted night aren't counted

    @Test func theDaysWithoutACountedNightArentCounted() {
        let pattern = rule.pattern(from: Self.analysis(timeAsleep: Self.timeAsleep(over: 6, under: 17)))

        #expect(pattern.uncountedNights == 7)
    }

    // MARK: - PATTERN-6: the finding covers the analysis's period and days

    @Test func theFindingCoversTheAnalysissPeriodAndDays() {
        let pattern = rule.pattern(from: Self.analysis(timeAsleep: Self.timeAsleep()))

        #expect(pattern.period == Self.period)
        #expect(pattern.days == 30)
    }
}
