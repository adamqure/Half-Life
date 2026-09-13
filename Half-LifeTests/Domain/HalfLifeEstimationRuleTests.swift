//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HalfLifeEstimationRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the half-life estimator's rule (EST-1 to EST-8 in the Half-Life Estimator article).
///
/// Most tests generate nights from a known half-life, so the rule's answer can be checked against the truth. Each
/// night's deep sleep falls, and its time awake rises, with the caffeine left at sleep onset.
struct HalfLifeEstimationRuleTests {

    let rule = HalfLifeEstimationRule()

    static let hour: TimeInterval = 3_600
    static let day: TimeInterval = 24 * hour

    /// The days of drinks generated before the first night, so every night's week of drinks is logged.
    static let historyDays = 7

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midnight at the start of Monday 1 June 2026, in UTC: the first generated day.
    static let start = utc.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? .distantPast

    static func halfLife(hours: Double) throws -> CaffeineHalfLife {
        try #require(CaffeineHalfLife(seconds: hours * hour))
    }

    static func hours(_ halfLife: CaffeineHalfLife) -> Double {
        halfLife.seconds / hour
    }

    /// Midnight at the start of generated day `index`.
    static func midnight(ofDay index: Int) -> Date {
        start.addingTimeInterval(Double(index) * day)
    }

    /// The width of the estimate's range, on a log scale, so ranges at different half-lives compare fairly.
    static func logWidth(_ estimate: HalfLifeEstimate) -> Double {
        log(estimate.upperBound.seconds / estimate.lowerBound.seconds)
    }

    /// Nights and intakes generated from a known half-life.
    struct Scenario {
        var nights: [HalfLifeEstimationRule.Night] = []
        var intakes: [CaffeineIntake] = []
        /// Noon on the day after the last night: when the estimate is made.
        var now = HalfLifeEstimationRuleTests.start
    }

    /// A reproducible pseudo-random sequence (a 64-bit linear congruential generator), so every run sees the same
    /// nights.
    struct Sequence {
        var state: UInt64

        mutating func uniform() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 11) / Double(UInt64(1) << 53)
        }

        /// A standard normal value, by the Box–Muller transform.
        mutating func normal() -> Double {
            let first = max(uniform(), .leastNonzeroMagnitude)
            let second = uniform()
            return (-2 * log(first)).squareRoot() * cos(2 * .pi * second)
        }
    }

    /// Generates ``historyDays`` days of drinks, then `count` days that each end in a night whose sleep depends on
    /// the caffeine left at sleep onset under `trueHours`.
    ///
    /// - Parameters:
    ///   - count: The number of nights.
    ///   - trueHours: The half-life the nights are generated with.
    ///   - effect: Minutes of deep sleep lost per milligram at sleep onset. Time awake rises by half as much.
    ///   - noise: The standard deviation, in minutes, of each night's deep sleep and time awake apart from caffeine.
    ///   - variedTiming: Whether drinks and bedtimes vary from day to day. Without it, every day is the same: one
    ///     150 mg drink at 9am, and sleep at 11pm.
    ///   - seed: The pseudo-random sequence's seed.
    static func scenario(
        count: Int, trueHours: Double, effect: Double, noise: Double, variedTiming: Bool = true, seed: UInt64 = 1
    ) throws -> Scenario {
        var random = Sequence(state: seed)
        let kinetics = CaffeineKinetics(halfLife: try halfLife(hours: trueHours), absorption: .standard)
        let decay = CaffeineDecayRule()
        var scenario = Scenario()
        func drink(_ midnight: Date, atHour hourOfDay: Double, milligrams: Double) {
            scenario.intakes.append(
                CaffeineIntake(
                    id: UUID(), milligrams: milligrams, consumedAt: midnight.addingTimeInterval(hourOfDay * hour)))
        }
        for index in 0..<(historyDays + count) {
            let midnight = midnight(ofDay: index)
            let onset: Date
            if variedTiming {
                drink(midnight, atHour: 7.5 + 2 * random.uniform(), milligrams: 60 + 120 * random.uniform())
                if random.uniform() < 0.6 {
                    drink(midnight, atHour: 12 + 8 * random.uniform(), milligrams: 60 + 160 * random.uniform())
                }
                onset = midnight.addingTimeInterval((22.5 + 1.5 * random.uniform()) * hour)
            } else {
                drink(midnight, atHour: 9, milligrams: 150)
                onset = midnight.addingTimeInterval(23 * hour)
            }
            guard index >= historyDays else { continue }
            let level = decay.level(at: onset, from: scenario.intakes, kinetics: kinetics).milligrams
            let deepMinutes = max(0, 90 - effect * level + noise * random.normal())
            let awakeMinutes = max(0, 20 + effect / 2 * level + noise * random.normal())
            let sleep = SleepNight(
                sleepOnset: onset, wake: onset.addingTimeInterval(7.5 * hour), deepSeconds: deepMinutes * 60,
                awakeSeconds: awakeMinutes * 60)
            scenario.nights.append(
                HalfLifeEstimationRule.Night(
                    sleep: sleep, steps: Int(8_000 + 4_000 * random.uniform()),
                    restingHeartRate: 58 + 6 * random.uniform()))
        }
        scenario.now = midnight(ofDay: historyDays + count).addingTimeInterval(12 * hour)
        return scenario
    }

    func estimate(_ scenario: Scenario, prior: CaffeineHalfLife = .standard) -> HalfLifeEstimate {
        rule.estimate(
            HalfLifeEstimationRule.Inputs(
                prior: prior, nights: scenario.nights, intakes: scenario.intakes, absorption: .standard),
            calendar: Self.utc, now: scenario.now)
    }

    /// The estimate with no nights: the prior and its range.
    func priorOnly(_ prior: CaffeineHalfLife = .standard) -> HalfLifeEstimate {
        rule.estimate(
            HalfLifeEstimationRule.Inputs(prior: prior, nights: [], intakes: [], absorption: .standard),
            calendar: Self.utc, now: Self.start)
    }

    /// Checks that the estimate recovered `trueHours`: its range contains it, and its half-life is less than half as
    /// far from it as the prior is, on a log scale.
    func expectRecovered(
        _ estimate: HalfLifeEstimate, trueHours: Double, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let found = Self.hours(estimate.halfLife)
        let range = Self.hours(estimate.lowerBound)...Self.hours(estimate.upperBound)
        #expect(range.contains(trueHours), "range \(range)", sourceLocation: sourceLocation)
        #expect(
            abs(log(found / trueHours)) < abs(log(Self.hours(estimate.prior) / trueHours)) / 2, "found \(found) h",
            sourceLocation: sourceLocation)
    }

    // MARK: - EST-1: with no nights, the estimate is the prior, with the prior's range

    @Test func withNoNightsTheEstimateIsThePrior() {
        let estimate = priorOnly()

        #expect(estimate.halfLife == .standard)
        #expect(estimate.prior == .standard)
        #expect(estimate.nightsUsed == 0)
        #expect(estimate.calculatedAt == Self.start)
        #expect(abs(Self.hours(estimate.lowerBound) - 3.294) < 0.001)
        #expect(abs(Self.hours(estimate.upperBound) - 9.183) < 0.001)
    }

    @Test func withNoDrinksTheEstimateIsThePrior() throws {
        var scenario = try Self.scenario(count: 30, trueHours: 9, effect: 0.3, noise: 5)
        scenario.intakes = []

        #expect(estimate(scenario) == priorOnly().withCalculation(at: scenario.now))
    }

    // MARK: - EST-2: fewer than 14 usable nights leave the prior, and a night needs 2 days of drinks before it

    @Test func thirteenNightsLeaveThePrior() throws {
        let estimate = estimate(try Self.scenario(count: 13, trueHours: 9, effect: 0.3, noise: 5))

        #expect(estimate.halfLife == .standard)
        #expect(estimate.nightsUsed == 0)
    }

    @Test func fourteenNightsAreUsed() throws {
        #expect(estimate(try Self.scenario(count: 14, trueHours: 9, effect: 0.3, noise: 5)).nightsUsed == 14)
    }

    @Test func nightsInTheFirstTwoDaysOfLoggingDontCount() throws {
        var sixteen = try Self.scenario(count: 16, trueHours: 9, effect: 0.3, noise: 5)
        sixteen.intakes.removeAll { $0.consumedAt < Self.midnight(ofDay: Self.historyDays) }
        var fifteen = try Self.scenario(count: 15, trueHours: 9, effect: 0.3, noise: 5)
        fifteen.intakes.removeAll { $0.consumedAt < Self.midnight(ofDay: Self.historyDays) }

        #expect(estimate(sixteen).nightsUsed == 14)
        #expect(estimate(fifteen).nightsUsed == 0)
    }

    @Test func nightsBeforeTheFirstDrinkDontCount() throws {
        var scenario = try Self.scenario(count: 20, trueHours: 9, effect: 0.3, noise: 5)
        scenario.intakes.removeAll { $0.consumedAt < Self.midnight(ofDay: Self.historyDays + 10) }

        let estimate = estimate(scenario)

        #expect(estimate.halfLife == .standard)
        #expect(estimate.nightsUsed == 0)
    }

    // MARK: - EST-3: with a clear effect and varied timing, it recovers the true half-life

    @Test func recoversALongHalfLife() throws {
        let estimate = estimate(try Self.scenario(count: 42, trueHours: 9, effect: 0.3, noise: 5))

        #expect(estimate.nightsUsed == 42)
        expectRecovered(estimate, trueHours: 9)
    }

    @Test func recoversAShortHalfLife() throws {
        expectRecovered(estimate(try Self.scenario(count: 42, trueHours: 3.5, effect: 0.3, noise: 5)), trueHours: 3.5)
    }

    @Test func recoversAHalfLifeFromAPriorTheSurveyLengthened() throws {
        let estimate = estimate(
            try Self.scenario(count: 42, trueHours: 5.5, effect: 0.3, noise: 5), prior: try Self.halfLife(hours: 8.25))

        expectRecovered(estimate, trueHours: 5.5)
    }

    // MARK: - EST-4: steps and resting heart rate are optional

    @Test func nightsWithoutStepsOrHeartRateStillCount() throws {
        var scenario = try Self.scenario(count: 42, trueHours: 9, effect: 0.3, noise: 5)
        scenario.nights = scenario.nights.map {
            HalfLifeEstimationRule.Night(sleep: $0.sleep, steps: nil, restingHeartRate: nil)
        }

        expectRecovered(estimate(scenario), trueHours: 9)
    }

    // MARK: - EST-5: without a caffeine effect, the estimate stays near the prior, and its range stays wide

    @Test(arguments: [UInt64(1), 2, 3])
    func withoutAnEffectTheEstimateStaysNearThePrior(seed: UInt64) throws {
        let estimate = estimate(try Self.scenario(count: 42, trueHours: 9, effect: 0, noise: 10, seed: seed))

        #expect(abs(log(Self.hours(estimate.halfLife) / 5.5)) < 0.15, "\(Self.hours(estimate.halfLife)) h")
        #expect(Self.logWidth(estimate) > 0.7 * Self.logWidth(priorOnly()))
    }

    // MARK: - EST-6: without variety in timing, even a strong effect leaves the prior

    @Test func withoutVarietyInTimingTheEstimateIsThePrior() throws {
        let estimate = estimate(
            try Self.scenario(count: 42, trueHours: 9, effect: 0.3, noise: 5, variedTiming: false))

        #expect(abs(log(Self.hours(estimate.halfLife) / 5.5)) < 0.02, "\(Self.hours(estimate.halfLife)) h")
        #expect(abs(Self.logWidth(estimate) / Self.logWidth(priorOnly()) - 1) < 0.05)
        #expect(estimate.nightsUsed == 42)
    }

    // MARK: - EST-7: the half-life and its range stay within 3 to 40 hours

    @Test func theRangeNeverGoesAboveFortyHours() throws {
        let estimate = priorOnly(try Self.halfLife(hours: 33))

        #expect(estimate.halfLife == (try Self.halfLife(hours: 33)))
        #expect(estimate.upperBound.seconds == HalfLifePriorRule.maximumSeconds)
    }

    @Test func theRangeNeverGoesBelowThreeHours() throws {
        let estimate = priorOnly(try Self.halfLife(hours: 3.3))

        #expect(estimate.lowerBound.seconds == HalfLifePriorRule.minimumSeconds)
    }

    // MARK: - EST-8: the range contains the half-life

    @Test func theRangeContainsTheHalfLife() throws {
        let estimate = estimate(try Self.scenario(count: 42, trueHours: 9, effect: 0.3, noise: 5))

        #expect(estimate.lowerBound.seconds <= estimate.halfLife.seconds)
        #expect(estimate.halfLife.seconds <= estimate.upperBound.seconds)
    }
}

extension HalfLifeEstimate {
    /// The same estimate, made at `date`.
    fileprivate func withCalculation(at date: Date) -> HalfLifeEstimate {
        HalfLifeEstimate(
            halfLife: halfLife, lowerBound: lowerBound, upperBound: upperBound, prior: prior, nightsUsed: nightsUsed,
            calculatedAt: date)
    }
}
