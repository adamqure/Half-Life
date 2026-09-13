//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HeartRateDetailFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the resting heart rate screen reduces the comparisons it observes (RHRSCREEN-1 in the Insights
/// article).
@MainActor
struct HeartRateDetailFeatureTests {

    /// RHRSCREEN-1: `task` subscribes to the comparison in the calendar dependency, and each comparison is reduced into
    /// `State`.
    @Test func taskReducesEachComparisonInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let day = Date(timeIntervalSinceReferenceDate: 0)
        let nextDay = day.addingTimeInterval(86_400)
        let nights = CaffeineNightHistory(
            nights: [
                CaffeineNight(
                    day: day, moment: day.addingTimeInterval(82_800), measuredAt: .sleepOnset, milligrams: 80,
                    isCaffeineNight: true)
            ],
            threshold: .standard, isDemo: false)
        let heartRates = RestingHeartRateHistory(
            days: [RestingHeartRateDay(day: nextDay, beatsPerMinute: 62)], isDemo: false)
        let expected = RestingHeartRateComparisonRule().comparison(of: heartRates, with: nights, calendar: tokyo)
        let sleepTolerance = FakeSleepToleranceRepository(caffeineNights: { _, calendar in
            calendar.timeZone == tokyoTimeZone ? [nights] : []
        })
        let healthData = FakeHealthDataRepository(restingHeartRates: { _, calendar in
            calendar.timeZone == tokyoTimeZone ? [heartRates] : []
        })
        let store = TestStore(initialState: HeartRateDetailFeature.State()) {
            HeartRateDetailFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeRestingHeartRateComparison = ObserveRestingHeartRateComparisonUseCase(
                sleepTolerance: sleepTolerance, healthData: healthData)
        }

        await store.send(.task)
        await store.receive(\.comparisonUpdated) {
            $0.comparison = expected
        }
        await store.finish()
    }
}
