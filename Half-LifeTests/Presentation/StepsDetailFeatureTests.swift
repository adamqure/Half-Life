//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StepsDetailFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Insights tab's steps screen against STEPSCARD-1 in the Insights article.
@MainActor
struct StepsDetailFeatureTests {

    /// STEPSCARD-1: `task` subscribes to the comparison in the calendar dependency, and each comparison is reduced into
    /// `State`.
    @Test func taskReducesTheComparisonInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let yesterday = try #require(tokyo.date(from: DateComponents(year: 2026, month: 6, day: 14)))
        let history = StepHistory(days: [DailySteps(day: yesterday, steps: 8_420)], isDemo: true)
        let nights = CaffeineNightHistory(nights: [], threshold: .standard, isDemo: true)
        let expected = StepsComparisonRule().comparison(
            caffeineNightDays: [], threshold: .standard, steps: history, calendar: tokyo)
        let useCase = ObserveStepsComparisonUseCase(
            sleepTolerance: FakeSleepToleranceRepository(caffeineNights: { _, calendar in
                calendar.timeZone == tokyoTimeZone ? [nights] : []
            }),
            healthData: FakeHealthDataRepository(stepHistories: { _, calendar in
                calendar.timeZone == tokyoTimeZone ? [history] : []
            }))
        let store = TestStore(initialState: StepsDetailFeature.State()) {
            StepsDetailFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeStepsComparison = useCase
        }

        await store.send(.task)
        await store.receive(\.comparisonUpdated) {
            $0.comparison = expected
        }
        await store.finish()
    }
}
