//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepToleranceRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Sleep screen's rule against TOL-1 to TOL-10 in the Insights article. The rule is pure, so its tests need
/// no fakes. They check the caffeine at sleep onset against ``CaffeineDecayRule``'s levels, so the screen and the curve
/// agree.
struct SleepToleranceRuleTests {

    let rule = SleepToleranceRule()

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    static let hour: TimeInterval = 3_600
    static let day: TimeInterval = 24 * hour
    /// Midnight at the start of day 0, in UTC.
    static let start = Date(timeIntervalSinceReferenceDate: 0)
    /// Noon on day 40.
    static let now = date(day: 40, hour: 12)
    /// A 100 mg coffee at 8am on every day from day 0 to day 40.
    static let mornings = (0...40).map { intake(100, day: $0, hour: 8) }

    static func date(day: Int, hour: Double) -> Date {
        start.addingTimeInterval(Double(day) * Self.day + hour * Self.hour)
    }

    static func intake(_ milligrams: Double, day: Int, hour: Double) -> CaffeineIntake {
        CaffeineIntake(id: UUID(), milligrams: milligrams, consumedAt: date(day: day, hour: hour))
    }

    /// One stretch of `stage` from `onset` hours on `day`, lasting `hours`.
    static func sleep(
        day: Int, onset: Double = 23, hours: Double = 7, stage: SleepStageInterval.Stage = .core
    ) -> SleepStageInterval {
        SleepStageInterval(
            stage: stage, start: date(day: day, hour: onset), end: date(day: day, hour: onset + hours))
    }

    /// The period the measured nights are analysed over: day 11 to day 40, inclusive.
    static let period = DateInterval(start: date(day: 11, hour: 0), end: date(day: 41, hour: 0))

    /// A night the rule has already measured, for the tolerance and comparison tests.
    static func night(
        _ milligrams: Double, asleepHours: Double, minutesToFallAsleep: Double? = nil
    ) -> SleepCaffeineNight {
        SleepCaffeineNight(
            sleepOnset: start, asleepSeconds: asleepHours * hour,
            secondsToFallAsleep: minutesToFallAsleep.map { $0 * 60 }, caffeineAtOnset: milligrams)
    }

    /// Nights at 0, 5, 10 … 95 mg: 7.5 hours asleep up to 50 mg, then 1.2 minutes less for each milligram over it.
    static let dropAtFifty = stride(from: 0.0, through: 95, by: 5).map { milligrams in
        night(milligrams, asleepHours: 7.5 - max(0, milligrams - 50) * 0.02)
    }

    func nights(
        _ intervals: [SleepStageInterval], intakes: [CaffeineIntake] = mornings,
        kinetics: CaffeineKinetics = .standard
    ) -> [SleepCaffeineNight] {
        rule.nights(from: intervals, intakes: intakes, kinetics: kinetics, now: Self.now, calendar: Self.utc)
    }

    // MARK: - TOL-1: a night is a session with at least 3 hours of sleep, from its first sleep to its last

    @Test func aNightRunsFromItsFirstSleepToItsLastAndCountsOnlyItsSleep() throws {
        let intervals = [
            Self.sleep(day: 30, onset: 23, hours: 3, stage: .core),
            Self.sleep(day: 30, onset: 26, hours: 1, stage: .deep),
            SleepStageInterval(
                stage: .awake, start: Self.date(day: 30, hour: 27), end: Self.date(day: 30, hour: 27 + 1.0 / 3)),
            SleepStageInterval(
                stage: .rem, start: Self.date(day: 30, hour: 27 + 1.0 / 3), end: Self.date(day: 30, hour: 30)),
        ]

        let night = try #require(nights(intervals).first)

        #expect(nights(intervals).count == 1)
        #expect(night.sleepOnset == Self.date(day: 30, hour: 23))
        #expect(night.asleepSeconds == 6 * Self.hour + 40 * 60)
    }

    @Test func sleepRecordedWithoutStagesMakesANight() {
        #expect(nights([Self.sleep(day: 30, stage: .asleepUnspecified)]).map(\.asleepSeconds) == [7 * Self.hour])
    }

    @Test func sleepThatTwoTrackersRecordedCountsOnce() {
        let intervals = [Self.sleep(day: 30), Self.sleep(day: 30, stage: .asleepUnspecified)]

        #expect(nights(intervals).map(\.asleepSeconds) == [7 * Self.hour])
    }

    @Test func aNapIsntANight() {
        #expect(nights([Self.sleep(day: 30, onset: 14, hours: 2)]).isEmpty)
    }

    @Test func timeInBedAloneIsntANight() {
        #expect(nights([Self.sleep(day: 30, stage: .inBed)]).isEmpty)
    }

    // MARK: - TOL-2: only nights that end in the last 30 days, after 2 days of logging, count

    /// Day 40 and the 29 days before it start at midnight on day 11. The night of day 9 ends on the morning of day 10.
    @Test func onlyNightsThatEndInTheLast30DaysCount() {
        let found = nights([Self.sleep(day: 9), Self.sleep(day: 10)])

        #expect(found.map(\.sleepOnset) == [Self.date(day: 10, hour: 23)])
    }

    @Test func aNightStillRunningAtTheCurrentTimeDoesntCount() {
        let intervals = [SleepStageInterval(stage: .core, start: Self.date(day: 40, hour: 2), end: Self.now)]

        #expect(nights(intervals).isEmpty)
        let later = rule.nights(
            from: intervals, intakes: Self.mornings, kinetics: .standard, now: Self.now + 1, calendar: Self.utc)
        #expect(later.count == 1)
    }

    /// Drinks start at 8am on day 20, so a night counts from 8am on day 22.
    @Test func nightsBeforeTwoDaysOfLoggingDontCount() {
        let intakes = (20...40).map { Self.intake(100, day: $0, hour: 8) }

        let found = nights([Self.sleep(day: 21), Self.sleep(day: 22)], intakes: intakes)

        #expect(found.map(\.sleepOnset) == [Self.date(day: 22, hour: 23)])
    }

    @Test func withNoDrinksThereAreNoNights() {
        #expect(nights([Self.sleep(day: 30)], intakes: []).isEmpty)
    }

    @Test func theNightsAreInOrderOfOnset() {
        let found = nights([Self.sleep(day: 31), Self.sleep(day: 30)])

        #expect(found.map(\.sleepOnset) == [Self.date(day: 30, hour: 23), Self.date(day: 31, hour: 23)])
    }

    /// The period ends at the next midnight, so it's the same all day, and so is an analysis of the same nights.
    @Test func thePeriodIsTodayAndThe29DaysBeforeIt() {
        #expect(rule.period(endingAt: Self.now, calendar: Self.utc) == Self.period)
    }

    @Test func thePeriodFollowsTheCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        #expect(rule.period(endingAt: Self.now, calendar: tokyo)?.start == Self.date(day: 10, hour: 15))
    }

    @Test func theSleepReadCoversThePeriodAndTheDayBefore() {
        let range = rule.range(endingAt: Self.now, calendar: Self.utc)

        #expect(range == DateInterval(start: Self.date(day: 10, hour: 0), end: Self.now))
    }

    // MARK: - TOL-3: the caffeine at sleep onset is the decay rule's level at that moment

    @Test func theCaffeineAtSleepOnsetIsTheDecayRulesLevel() throws {
        let intakes = Self.mornings + [Self.intake(200, day: 30, hour: 16)]
        let kinetics = CaffeineKinetics(
            halfLife: try #require(CaffeineHalfLife(seconds: 8 * Self.hour)), absorption: .standard)
        let onset = Self.date(day: 30, hour: 23)

        let night = try #require(nights([Self.sleep(day: 30)], intakes: intakes, kinetics: kinetics).first)

        let expected = CaffeineDecayRule().level(at: onset, from: intakes, kinetics: kinetics).milligrams
        #expect(abs(night.caffeineAtOnset - expected) < 0.000_1)
        #expect(night.caffeineAtOnset > 90)
    }

    // MARK: - TOL-4: the time to fall asleep runs from getting into bed to the first sleep

    @Test func theTimeToFallAsleepRunsFromGettingIntoBedToTheFirstSleep() {
        let inBed = SleepStageInterval(
            stage: .inBed, start: Self.date(day: 30, hour: 22.5), end: Self.date(day: 30, hour: 30.2))

        #expect(nights([inBed, Self.sleep(day: 30)]).map(\.secondsToFallAsleep) == [30 * 60])
    }

    @Test func withoutTimeInBedTheTimeToFallAsleepIsUnknown() {
        #expect(nights([Self.sleep(day: 30)]).map(\.secondsToFallAsleep) == [nil])
    }

    @Test func timeInBedThatStartsAfterTheFirstSleepDoesntCount() {
        let inBed = SleepStageInterval(
            stage: .inBed, start: Self.date(day: 30, hour: 23.5), end: Self.date(day: 30, hour: 30.2))

        #expect(nights([inBed, Self.sleep(day: 30)]).map(\.secondsToFallAsleep) == [nil])
    }

    // MARK: - TOL-5: the tolerance is the caffeine at sleep onset above which time asleep starts to drop

    @Test func theToleranceIsWhereTimeAsleepStartsToDrop() throws {
        let tolerance = try #require(rule.tolerance(of: Self.dropAtFifty))

        #expect(tolerance == SleepTolerance(milligrams: 50, nightsUnder: 11, nightsOver: 9))
    }

    // MARK: - TOL-6: with fewer than 5 nights on either side, there's no tolerance

    /// Sixteen nights under 20 mg and four at 90 mg: no candidate from 20 to 80 mg has 5 nights over it.
    @Test func withFewerThanFiveNightsOverItThereIsNoTolerance() {
        let nights =
            (0..<16).map { Self.night(Double($0), asleepHours: 7.5) }
            + (0..<4).map { _ in
                Self.night(90, asleepHours: 5)
            }

        #expect(rule.tolerance(of: nights) == nil)
    }

    @Test func withFewerThanFiveNightsUnderItThereIsNoTolerance() {
        let nights =
            (0..<4).map { _ in Self.night(10, asleepHours: 8) }
            + (0..<16).map {
                Self.night(90 + Double($0), asleepHours: 6)
            }

        #expect(rule.tolerance(of: nights) == nil)
    }

    // MARK: - TOL-7: when time asleep doesn't drop, there's no tolerance

    @Test func whenTimeAsleepStaysLevelThereIsNoTolerance() {
        let nights = stride(from: 0.0, through: 95, by: 5).map { Self.night($0, asleepHours: 7) }

        #expect(rule.tolerance(of: nights) == nil)
    }

    @Test func whenTimeAsleepRisesWithCaffeineThereIsNoTolerance() {
        let nights = stride(from: 0.0, through: 95, by: 5).map { Self.night($0, asleepHours: 7 + $0 * 0.01) }

        #expect(rule.tolerance(of: nights) == nil)
    }

    // MARK: - TOL-8: the tolerance is a whole 5 mg from 20 to 80 mg

    @Test func aDropFromTheFirstMilligramGivesTheLowestTolerance() throws {
        let nights = stride(from: 0.0, through: 95, by: 5).map { Self.night($0, asleepHours: 8 - $0 * 0.02) }

        #expect(try #require(rule.tolerance(of: nights)).milligrams == 20)
    }

    @Test func aDropAbove80MgGivesTheHighestTolerance() throws {
        let nights = stride(from: 0.0, through: 140, by: 5).map { milligrams in
            Self.night(milligrams, asleepHours: 7.5 - max(0, milligrams - 100) * 0.03)
        }

        #expect(try #require(rule.tolerance(of: nights)).milligrams == 80)
    }

    @Test func aDropBetweenStepsGivesAWhole5Mg() throws {
        let nights = stride(from: 0.0, through: 95, by: 5).map { milligrams in
            Self.night(milligrams, asleepHours: 7.5 - max(0, milligrams - 47) * 0.02)
        }

        let milligrams = try #require(rule.tolerance(of: nights)).milligrams

        #expect(milligrams.truncatingRemainder(dividingBy: 5) == 0)
        #expect((45...50).contains(milligrams))
    }

    // MARK: - TOL-9: time asleep is compared either side of the threshold in use

    @Test func withAToleranceTimeAsleepIsComparedEitherSideOfIt() throws {
        let analysis = rule.analysis(period: Self.period, of: Self.dropAtFifty, isDemo: false)
        let overHours = stride(from: 55.0, through: 95, by: 5).map { 7.5 - ($0 - 50) * 0.02 }

        let timeAsleep = try #require(analysis.timeAsleep)

        #expect(analysis.threshold.milligrams == 50)
        #expect(timeAsleep.nightsUnder == 11)
        #expect(timeAsleep.nightsOver == 9)
        #expect(abs(timeAsleep.underSeconds - 7.5 * Self.hour) < 0.001)
        #expect(abs(timeAsleep.overSeconds - overHours.reduce(0, +) / 9 * Self.hour) < 0.001)
    }

    @Test func withoutAToleranceTimeAsleepIsComparedEitherSideOf40Mg() throws {
        let nights = stride(from: 0.0, through: 95, by: 5).map { Self.night($0, asleepHours: 7) }

        let analysis = rule.analysis(period: Self.period, of: nights, isDemo: true)

        #expect(analysis.tolerance == nil)
        #expect(analysis.threshold == .standard)
        #expect(analysis.isDemo)
        #expect(try #require(analysis.timeAsleep).nightsUnder == 9)
        #expect(try #require(analysis.timeAsleep).nightsOver == 11)
    }

    @Test func withFewerThanFiveNightsOnEitherSideTimeAsleepIsntCompared() {
        let under = (0..<10).map { _ in Self.night(10, asleepHours: 7) }
        let nights = under + (0..<4).map { _ in Self.night(60, asleepHours: 6) }

        #expect(rule.analysis(period: Self.period, of: nights, isDemo: false).timeAsleep == nil)
    }

    // MARK: - TOL-10: the time to fall asleep is compared either side of the threshold, among the nights with it

    @Test func theTimeToFallAsleepIsComparedAmongNightsThatHaveIt() throws {
        let under = (0..<6).map { _ in Self.night(10, asleepHours: 7, minutesToFallAsleep: 12) }
        let over = (0..<5).map { _ in Self.night(60, asleepHours: 7, minutesToFallAsleep: 40) }
        let unknown = (0..<3).map { _ in Self.night(60, asleepHours: 7) }

        let analysis = rule.analysis(period: Self.period, of: under + over + unknown, isDemo: false)
        let comparison = try #require(analysis.timeToFallAsleep)

        let expected = SleepComparison(underSeconds: 12 * 60, overSeconds: 40 * 60, nightsUnder: 6, nightsOver: 5)
        #expect(comparison == expected)
    }

    @Test func withFewerThanFiveNightsOnEitherSideTheTimeToFallAsleepIsntCompared() {
        let under = (0..<6).map { _ in Self.night(10, asleepHours: 7, minutesToFallAsleep: 12) }
        let over = (0..<4).map { _ in Self.night(60, asleepHours: 7, minutesToFallAsleep: 40) }
        let unknown = (0..<3).map { _ in Self.night(60, asleepHours: 7) }

        #expect(rule.analysis(period: Self.period, of: under + over + unknown, isDemo: false).timeToFallAsleep == nil)
    }

    // MARK: - TOL-11: the onsets are every recorded night's, before or in the period, once 2 days of drinks are logged

    @Test func theOnsetsAreEveryRecordedNightsIncludingBeforeThePeriod() {
        let intervals = [Self.sleep(day: 5), Self.sleep(day: 30), Self.sleep(day: 31, onset: 14, hours: 2)]

        let onsets = rule.onsets(from: intervals, intakes: Self.mornings, now: Self.now)

        #expect(onsets == [Self.date(day: 5, hour: 23), Self.date(day: 30, hour: 23)])
    }

    @Test func onsetsBeforeTwoDaysOfLoggingAreLeftOut() {
        let intakes = (20...40).map { Self.intake(100, day: $0, hour: 8) }

        let onsets = rule.onsets(from: [Self.sleep(day: 21), Self.sleep(day: 22)], intakes: intakes, now: Self.now)

        #expect(onsets == [Self.date(day: 22, hour: 23)])
    }

    @Test func aNightStillRunningHasNoOnsetYet() {
        let intervals = [SleepStageInterval(stage: .core, start: Self.date(day: 40, hour: 2), end: Self.now)]

        #expect(rule.onsets(from: intervals, intakes: Self.mornings, now: Self.now).isEmpty)
    }

    @Test func theAnalysisKeepsItsNights() {
        #expect(rule.analysis(period: Self.period, of: Self.dropAtFifty, isDemo: false).nights == Self.dropAtFifty)
    }

    @Test func theAnalysisOfTheSleepReadMeasuresItsNights() throws {
        let intervals = [Self.sleep(day: 30), Self.sleep(day: 31)]
        let inputs = SleepToleranceRule.Inputs(
            intervals: intervals, intakes: Self.mornings, kinetics: .standard, isDemo: true)

        let analysis = try #require(rule.analysis(inputs, now: Self.now, calendar: Self.utc))

        #expect(analysis.nights == nights(intervals))
        #expect(analysis.isDemo)
        #expect(analysis.period == Self.period)
        #expect(analysis.days == 30)
    }
}
