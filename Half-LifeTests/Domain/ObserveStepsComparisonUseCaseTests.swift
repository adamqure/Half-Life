//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveStepsComparisonUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the steps comparison combines the caffeine nights and the step history, and executes
/// ``StepsComparisonRule`` on them (STEPSUSE-1 to STEPSUSE-3 in the Insights article).
///
/// Each fake stream sends its values, then finishes, so the two can arrive in either order. The tests check only what
/// holds in every order.
struct ObserveStepsComparisonUseCaseTests {
    let rule = StepsComparisonRule()
    let tokyo: Calendar

    init() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        self.tokyo = tokyo
    }

    /// Midnight on June `day`, 2026, in Tokyo.
    func june(_ day: Int) throws -> Date {
        try #require(tokyo.date(from: DateComponents(year: 2026, month: 6, day: day)))
    }

    /// The nights that followed June 12, 13, and 14, each with `milligrams` at its 11pm bedtime, and a caffeine night
    /// when that's over the standard 40 mg.
    func nights(_ milligrams: [Double]) throws -> CaffeineNightHistory {
        let nights = try zip(12...14, milligrams).map { day, amount in
            let midnight = try june(day)
            return CaffeineNight(
                day: midnight, moment: midnight.addingTimeInterval(23 * 3_600), measuredAt: .bedtime,
                milligrams: amount, isCaffeineNight: amount > SleepThreshold.standard.milligrams)
        }
        return CaffeineNightHistory(nights: nights, threshold: .standard, isDemo: false)
    }

    /// The steps of June 13 and 14.
    func steps(_ june13: Int?, _ june14: Int?) throws -> StepHistory {
        StepHistory(
            days: [DailySteps(day: try june(13), steps: june13), DailySteps(day: try june(14), steps: june14)],
            isDemo: false)
    }

    /// The rule's comparison of `nights` and `steps`, as the use case should make it.
    func expected(_ nights: CaffeineNightHistory, _ steps: StepHistory) -> StepsComparison {
        rule.comparison(
            caffeineNightDays: Set(nights.nights.filter(\.isCaffeineNight).map(\.day)), threshold: nights.threshold,
            steps: steps, calendar: tokyo)
    }

    /// A use case over fakes that send `histories` for the last 31 nights, and `stepHistories` for the last 30 days,
    /// only in Tokyo.
    func useCase(histories: [CaffeineNightHistory], stepHistories: [StepHistory]) -> ObserveStepsComparisonUseCase {
        let tokyoTimeZone = tokyo.timeZone
        return ObserveStepsComparisonUseCase(
            sleepTolerance: FakeSleepToleranceRepository(caffeineNights: { days, calendar in
                days == StepsComparisonRule.dayCount + 1 && calendar.timeZone == tokyoTimeZone ? histories : []
            }),
            healthData: FakeHealthDataRepository(stepHistories: { days, calendar in
                days == StepsComparisonRule.dayCount && calendar.timeZone == tokyoTimeZone ? stepHistories : []
            }))
    }

    func received(from observe: ObserveStepsComparisonUseCase) async throws -> [StepsComparison] {
        var received: [StepsComparison] = []
        for await comparison in try await executeThroughProtocol(observe, tokyo) {
            received.append(comparison)
        }
        return received
    }

    // MARK: - STEPSUSE-1: the rule's comparison of the last 31 nights and the last 30 days of steps

    @Test func streamsTheRulesComparisonOfTheNightsAndTheSteps() async throws {
        let history = try nights([120, 10, 10])
        let stepHistory = try steps(7_000, 9_000)

        let received = try await received(from: useCase(histories: [history], stepHistories: [stepHistory]))

        #expect(received == [expected(history, stepHistory)])
        #expect(received.first?.days.map(\.followsCaffeineNight) == [true, false])
    }

    // MARK: - STEPSUSE-2: after either stream sends, the latest of each is compared

    @Test func theLastComparisonIsOfTheLatestNightsAndSteps() async throws {
        let first = try nights([10, 10, 10])
        let second = try nights([120, 10, 10])
        let firstSteps = try steps(8_000, 9_000)
        let secondSteps = try steps(7_000, 9_000)

        let received = try await received(
            from: useCase(histories: [first, second], stepHistories: [firstSteps, secondSteps]))

        #expect(received.last == expected(second, secondSteps))
        #expect(zip(received, received.dropFirst()).allSatisfy { $0 != $1 })
    }

    // MARK: - STEPSUSE-3: a change that leaves the comparison as it was sends nothing

    @Test func aChangeThatLeavesTheComparisonAsItWasSendsNothing() async throws {
        let stepHistory = try steps(8_000, 9_000)
        // Only the last night's amount changes, and it stays a caffeine-free night that no step day follows.
        let first = try nights([10, 10, 10])
        let second = try nights([10, 10, 30])

        let received = try await received(from: useCase(histories: [first, second], stepHistories: [stepHistory]))

        #expect(received == [expected(first, stepHistory)])
    }
}
