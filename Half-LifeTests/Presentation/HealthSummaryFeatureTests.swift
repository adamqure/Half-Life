//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthSummaryFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Apple Health card's feature against HCARD-1 and HCARD-2, and its place in the Today screen against
/// TODAY-5, in the Apple Health Card and Today Screen articles.
@MainActor
struct HealthSummaryFeatureTests {

    // MARK: - HCARD-1: `task` subscribes in the calendar dependency, and each summary is reduced into State

    @Test func taskReducesEachSummaryInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let morning = HealthSummary(stepsToday: 1_200)
        let afternoon = HealthSummary(stepsToday: 6_400, restingHeartRateToday: 58)
        let repository = FakeHealthDataRepository(summaries: {
            $0.timeZone == tokyoTimeZone ? [morning, afternoon] : []
        })
        let store = TestStore(initialState: HealthSummaryFeature.State()) {
            HealthSummaryFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeHealthSummary = ObserveHealthSummaryUseCase(repository: repository)
        }

        await store.send(.task)
        await store.receive(\.summaryUpdated) {
            $0.summary = morning
        }
        await store.receive(\.summaryUpdated) {
            $0.summary = afternoon
        }
        await store.finish()
    }

    // MARK: - HCARD-2: the card shows only once a summary with a metric has arrived

    @Test func theCardShowsOnlyForASummaryWithAMetric() {
        #expect(!HealthSummaryFeature.State().isShown)
        #expect(!HealthSummaryFeature.State(summary: .empty).isShown)
        #expect(!HealthSummaryFeature.State(summary: HealthSummary(isDemo: true)).isShown)
        #expect(HealthSummaryFeature.State(summary: HealthSummary(stepsToday: 0)).isShown)
        #expect(HealthSummaryFeature.State(summary: HealthSummary(lastNight: .inBedOnly(seconds: 3 * 3_600))).isShown)
    }

    // MARK: - TODAY-5: the card's actions reach its feature, and its state appears under `healthSummary`

    @Test func healthSummaryActionsReachTheHealthSummaryFeature() async {
        let summary = HealthSummary(stepsToday: 8_420)
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeHealthSummary = ObserveHealthSummaryUseCase(
                repository: FakeHealthDataRepository(summaries: { _ in [summary] }))
        }

        await store.send(.healthSummary(.task))
        await store.receive(\.healthSummary.summaryUpdated) {
            $0.healthSummary.summary = summary
        }
        await store.finish()
    }
}
