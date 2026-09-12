//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineDecayRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the decay rule against the Caffeine Decay Model article: requirements RULE-1 to RULE-8, and the worked
/// examples, which are the reference values for RULE-1. Unless a test says otherwise, it uses the standard 5.5-hour
/// half-life and the standard 13-minute absorption half-life, together ``CaffeineKinetics/standard``.
struct CaffeineDecayRuleTests {

    let rule = CaffeineDecayRule()
    let kinetics = CaffeineKinetics.standard

    /// Midnight on the day of the worked examples. It sits on a whole minute, like every sample.
    static let midnight = Date(timeIntervalSinceReferenceDate: 0)

    /// The worked examples' day of drinks: 128 mg at 8:00am, 64 mg at 10:45am, and 205 mg at 3:00pm.
    static let dayOfDrinks = [intake(128, hours: 8), intake(64, hours: 10.75), intake(205, hours: 15)]

    /// The date `hours` after midnight.
    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func intake(_ milligrams: Double, hours: Double) -> CaffeineIntake {
        CaffeineIntake(id: UUID(), milligrams: milligrams, consumedAt: date(hours))
    }

    /// Rounds to two decimal places, the precision the model is specified to.
    static func rounded(_ milligrams: Double) -> Double {
        (milligrams * 100).rounded() / 100
    }

    /// The level at `date`, with the standard half-life and absorption rate.
    func level(at date: Date, from intakes: [CaffeineIntake]) -> CaffeineLevel {
        rule.level(at: date, from: intakes, kinetics: kinetics)
    }

    /// The curve for `now`, with the standard half-life and absorption rate.
    func curve(from intakes: [CaffeineIntake], now: Date) -> [CaffeineLevel] {
        rule.curve(from: intakes, kinetics: kinetics, now: now)
    }

    /// The intakes negligible at the first sample of the window for `now`, with the standard half-life and absorption
    /// rate.
    func negligible(from intakes: [CaffeineIntake], now: Date) -> [CaffeineIntake] {
        rule.negligibleIntakes(from: intakes, kinetics: kinetics, now: now)
    }

    @Test func constantsMatchTheArticle() {
        #expect(CaffeineDecayRule.negligibleMilligrams == 0.5)
        #expect(CaffeineDecayRule.sampleSpacing == 60)
        #expect(CaffeineDecayRule.windowRadius == 12 * 3_600)
        #expect(CaffeineDecayRule.sampleCount == 1_440)
    }

    // MARK: - RULE-1: the level is the sum of each counting intake's Bateman curve

    @Test(
        arguments: [
            (0.25, 108.17), (0.5, 153.43), (1, 175.05), (2, 161.47), (4, 125.76), (5.5, 104.10), (7, 86.17),
            (11, 52.05), (16.5, 26.03), (24, 10.11),
        ] as [(Double, Double)])
    func singleDrinkMatchesWorkedExample(hoursSinceDrinking: Double, expected: Double) {
        let level = level(at: Self.date(hoursSinceDrinking), from: [Self.intake(200, hours: 0)])
        #expect(level.date == Self.date(hoursSinceDrinking))
        #expect(Self.rounded(level.milligrams) == expected)
    }

    @Test(
        arguments: [
            (7 + 59.0 / 60, 0.00), (8, 0.00), (8.5, 98.20), (10.75, 94.20), (12, 136.18), (15, 94.14),
            (16, 262.43), (23, 112.22),
        ] as [(Double, Double)])
    func dayOfDrinksMatchesWorkedExample(hours: Double, expected: Double) {
        let level = level(at: Self.date(hours), from: Self.dayOfDrinks)
        #expect(Self.rounded(level.milligrams) == expected)
    }

    /// When absorption and elimination share a half-life, the Bateman formula divides by zero, so the rule uses its
    /// limit. 100 mg with both half-lives at 1 hour leaves 34.66 mg after 1 hour.
    @Test func equalHalfLivesUseTheLimitOfTheFormula() throws {
        let oneHour = try #require(CaffeineHalfLife(seconds: 3_600))
        let sameRate = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_600))

        let level = rule.level(
            at: Self.date(1), from: [Self.intake(100, hours: 0)],
            kinetics: CaffeineKinetics(halfLife: oneHour, absorption: sameRate))

        #expect(Self.rounded(level.milligrams) == 34.66)
    }

    /// The limit joins the formula smoothly: a millisecond's difference in the half-lives barely moves the level.
    @Test func nearlyEqualHalfLivesGiveNearlyTheSameLevel() throws {
        let oneHour = try #require(CaffeineHalfLife(seconds: 3_600))
        let sameRate = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_600))
        let nearRate = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_599.999))
        let intakes = [Self.intake(100, hours: 0)]

        let same = rule.level(
            at: Self.date(1), from: intakes, kinetics: CaffeineKinetics(halfLife: oneHour, absorption: sameRate))
        let near = rule.level(
            at: Self.date(1), from: intakes, kinetics: CaffeineKinetics(halfLife: oneHour, absorption: nearRate))

        #expect(abs(same.milligrams - near.milligrams) < 0.001)
    }

    // MARK: - RULE-2: nothing before or at consumedAt, rising to a peak

    @Test func intakeAddsNothingBeforeItsConsumedAt() {
        let level = level(at: Self.date(8).addingTimeInterval(-1), from: [Self.intake(128, hours: 8)])
        #expect(level.milligrams == 0)
    }

    /// At consumedAt, the whole dose is still in the stomach.
    @Test func intakeAddsNothingAtExactlyItsConsumedAt() {
        let level = level(at: Self.date(8), from: [Self.intake(128, hours: 8)])
        #expect(level.milligrams == 0)
    }

    /// 200 mg peaks at 175.16 mg, 3,788.64 seconds (about 63 minutes) after it's consumed. A minute either side, the
    /// level is lower.
    @Test func intakePeaksAboutSixtyThreeMinutesAfterItsConsumed() {
        let intakes = [Self.intake(200, hours: 0)]
        let peak = level(at: Self.midnight.addingTimeInterval(3_788.64), from: intakes)
        let before = level(at: Self.midnight.addingTimeInterval(3_788.64 - 60), from: intakes)
        let after = level(at: Self.midnight.addingTimeInterval(3_788.64 + 60), from: intakes)

        #expect(Self.rounded(peak.milligrams) == 175.16)
        #expect(before.milligrams < peak.milligrams)
        #expect(after.milligrams < peak.milligrams)
    }

    // MARK: - RULE-3: an intake counts until it's past its peak and below 0.5 mg

    /// 128 mg falls below 0.5 mg 159,548.07 seconds (about 44 hours 19 minutes) after it's consumed.
    @Test func intakeStillCountsWhileAtLeastHalfAMilligramRemains() {
        let intake = Self.intake(128, hours: 0)
        let date = Self.midnight.addingTimeInterval(159_548)

        #expect(level(at: date, from: [intake]).milligrams >= 0.5)
        #expect(rule.isCounting(intake, at: date, kinetics: kinetics))
    }

    @Test func intakeStopsCountingOnceItsPastItsPeakAndBelowHalfAMilligram() {
        let intake = Self.intake(128, hours: 0)
        let date = Self.midnight.addingTimeInterval(159_549)

        #expect(level(at: date, from: [intake]).milligrams == 0)
        #expect(!rule.isCounting(intake, at: date, kinetics: kinetics))
    }

    /// A drink logged this minute is 0 mg, but it counts: its caffeine is on its way.
    @Test func intakeCountsFromExactlyItsConsumedAt() {
        let intake = Self.intake(128, hours: 8)

        #expect(rule.isCounting(intake, at: Self.date(8), kinetics: kinetics))
        #expect(
            !rule.isCounting(
                intake, at: Self.date(8).addingTimeInterval(-1), kinetics: kinetics))
    }

    /// 0.4 mg never reaches 0.5 mg, so it counts only until its peak, about 63 minutes after it's consumed.
    @Test func intakeOfLessThanHalfAMilligramCountsOnlyUntilItsPeak() {
        let intakes = [Self.intake(0.4, hours: 0)]
        #expect(Self.rounded(level(at: Self.date(0.5), from: intakes).milligrams) == 0.31)
        #expect(level(at: Self.midnight.addingTimeInterval(65 * 60), from: intakes).milligrams == 0)
    }

    // MARK: - RULE-4: negligible intakes are judged at the window's first sample

    /// At 56 hours 20 minutes, the first sample is 44 hours 20 minutes, when 128 mg is below 0.5 mg.
    @Test func intakeIsNegligibleOnceItStopsCountingAtTheFirstSample() {
        let intake = Self.intake(128, hours: 0)
        let negligible = negligible(from: [intake], now: Self.date(56).addingTimeInterval(20 * 60))
        #expect(negligible == [intake])
    }

    /// At 56 hours 19 minutes, the first sample is 44 hours 19 minutes, when 128 mg is still above 0.5 mg.
    @Test func intakeIsntNegligibleWhileItCountsAtTheFirstSample() {
        let negligible = negligible(
            from: [Self.intake(128, hours: 0)], now: Self.date(56).addingTimeInterval(19 * 60))
        #expect(negligible.isEmpty)
    }

    /// 0.4 mg never counts past its peak, but it isn't negligible until the first sample reaches its peak.
    @Test func intakeIsntNegligibleBeforeItsPeakAtTheFirstSample() {
        let intake = Self.intake(0.4, hours: 0)
        #expect(negligible(from: [intake], now: Self.date(12.5)).isEmpty)
        #expect(negligible(from: [intake], now: Self.date(12).addingTimeInterval(64 * 60)) == [intake])
    }

    @Test func intakeConsumedAfterTheFirstSampleIsNeverNegligible() {
        #expect(negligible(from: [Self.intake(0.4, hours: 10)], now: Self.date(12)).isEmpty)
    }

    /// 64 mg stops counting after about 38.82 hours. At 51 hours, the first sample is 39 hours, just past that.
    @Test func returnsExactlyTheNegligibleIntakes() {
        let old = Self.intake(64, hours: 0)
        let recent = Self.intake(200, hours: 40)
        #expect(negligible(from: [old, recent], now: Self.date(51)) == [old])
    }

    // MARK: - RULE-5: 1,440 levels, 12 hours either side of the current minute

    @Test func curveHasFourteenHundredFortyLevels() {
        #expect(curve(from: Self.dayOfDrinks, now: Self.date(12)).count == 1_440)
    }

    /// At 12:00:59, the current minute is 12:00, so the window runs from midnight.
    @Test func curveStartsTwelveHoursBeforeTheCurrentMinute() {
        let curve = curve(from: Self.dayOfDrinks, now: Self.date(12).addingTimeInterval(59))
        #expect(curve.first?.date == Self.date(0))
        #expect(curve[720].date == Self.date(12))
        #expect(curve.last?.date == Self.date(24).addingTimeInterval(-60))
    }

    @Test func curveWithNoIntakesIsAllZeros() {
        let curve = curve(from: [], now: Self.date(12))
        #expect(curve.count == 1_440)
        #expect(curve.allSatisfy { $0.milligrams == 0 })
    }

    @Test func eachCurveLevelIsTheLevelAtItsDate() {
        let curve = curve(from: Self.dayOfDrinks, now: Self.date(20))
        #expect(curve.allSatisfy { $0 == level(at: $0.date, from: Self.dayOfDrinks) })
    }

    /// At 8:00pm the window runs from 8:00am, so 4:00pm is sample 480 and 11:00pm is sample 900.
    @Test func curveContainsTheWorkedExamples() {
        let curve = curve(from: Self.dayOfDrinks, now: Self.date(20))
        #expect(Self.rounded(curve[480].milligrams) == 262.43)
        #expect(Self.rounded(curve[900].milligrams) == 112.22)
    }

    /// The curve uses the absorption rate it's given: with a 1-hour absorption half-life, 11:00pm is higher.
    @Test func curveUsesTheAbsorptionRateItsGiven() throws {
        let oneHour = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_600))
        let slowKinetics = CaffeineKinetics(halfLife: .standard, absorption: oneHour)
        let slow = rule.curve(from: Self.dayOfDrinks, kinetics: slowKinetics, now: Self.date(20))
        #expect(slow != curve(from: Self.dayOfDrinks, now: Self.date(20)))
        #expect(
            slow.allSatisfy {
                $0 == rule.level(at: $0.date, from: Self.dayOfDrinks, kinetics: slowKinetics)
            })
    }

    // MARK: - RULE-6: pure, with the current time as an input

    @Test func sameInputsGiveTheSameCurve() {
        #expect(curve(from: Self.dayOfDrinks, now: Self.date(20)) == curve(from: Self.dayOfDrinks, now: Self.date(20)))
    }

    // MARK: - RULE-7: one minute apart, on whole clock minutes

    @Test func curveSamplesAreOneMinuteApartOnWholeMinutes() {
        let curve = curve(from: Self.dayOfDrinks, now: Self.date(12).addingTimeInterval(37))
        let gaps = zip(curve, curve.dropFirst()).map { $1.date.timeIntervalSince($0.date) }
        #expect(gaps.allSatisfy { $0 == 60 })
        #expect(curve.allSatisfy { $0.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) == 0 })
    }

    // MARK: - RULE-8: an intake is half gone once its own level falls to half its dose, after its peak

    /// Any dose is half gone 20,948.07 seconds (5 hours 49 minutes 8 seconds) after it's consumed. That's 19 minutes
    /// later than one half-life, because the caffeine reached the body over time.
    @Test(arguments: [64.0, 205.0])
    func intakeIsHalfGoneWhenItsLevelFallsToHalfItsDoseAfterItsPeak(milligrams: Double) {
        let intake = Self.intake(milligrams, hours: 15)
        let halfGone = rule.halfGoneDate(of: intake, kinetics: kinetics)
        #expect(abs(halfGone.timeIntervalSince(Self.date(15)) - 20_948.07) < 0.01)
    }

    /// With both half-lives at 1 hour, an intake peaks at about 37% of its dose, so it's already half gone at its
    /// peak, 1 hour / ln 2 after it's consumed.
    @Test func intakeThatNeverReachesHalfItsDoseIsHalfGoneAtItsPeak() throws {
        let oneHour = try #require(CaffeineHalfLife(seconds: 3_600))
        let sameRate = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_600))
        let intake = Self.intake(100, hours: 0)

        let halfGone = rule.halfGoneDate(
            of: intake, kinetics: CaffeineKinetics(halfLife: oneHour, absorption: sameRate))

        #expect(abs(halfGone.timeIntervalSince(Self.midnight) - 3_600 / log(2)) < 0.01)
    }
}
