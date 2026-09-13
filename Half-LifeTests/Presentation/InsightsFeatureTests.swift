//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightsFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the Insights tab composes its cards, and that the root runs the tab (INSIGHTS-1 in the Insights
/// article).
@MainActor
struct InsightsFeatureTests {

    static let window = SleepWindow(
        evening: Date(timeIntervalSinceReferenceDate: 18 * 3_600),
        bedtime: Date(timeIntervalSinceReferenceDate: 22.5 * 3_600),
        clearsAt: Date(timeIntervalSinceReferenceDate: 18 * 3_600),
        window: DateInterval(start: Date(timeIntervalSinceReferenceDate: 22.5 * 3_600), duration: 5_400),
        chartEnd: Date(timeIntervalSinceReferenceDate: 28 * 3_600), threshold: .standard, levels: [])

    /// INSIGHTS-1: the sleep window card's actions reach `SleepWindowFeature`, and its state appears under
    /// `sleepWindow`.
    @Test func sleepWindowActionsReachTheSleepWindowFeature() async {
        let window = Self.window
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeSleepWindow = ObserveSleepWindowUseCase(
                repository: FakeCaffeineDecayRepository(sleepWindows: { _ in [window] }))
        }

        await store.send(.sleepWindow(.task))
        await store.receive(\.sleepWindow.windowUpdated) {
            $0.sleepWindow.window = Self.window
        }
        await store.finish()
    }

    /// INSIGHTS-2: the last 7 days card's actions reach `LastSevenDaysFeature`, and its state appears under
    /// `lastSevenDays`.
    @Test func lastSevenDaysActionsReachTheLastSevenDaysFeature() async {
        let week = (0..<7).map { index in
            DrinkLogDay(
                intake: DailyCaffeineIntake(
                    day: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400), milligrams: 0),
                drinks: [])
        }
        // The repository's 8 days to today lose today, so the card gets `week`.
        let today = DrinkLogDay(
            intake: DailyCaffeineIntake(day: Date(timeIntervalSinceReferenceDate: 7 * 86_400), milligrams: 0),
            drinks: [])
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeDrinkLogWeek = ObserveDrinkLogWeekUseCase(
                repository: FakeDrinkLogRepository(recentDays: { _, _ in [week + [today]] }))
            $0.observeSleepWeek = ObserveSleepWeekUseCase(repository: FakeHealthDataRepository())
        }

        await store.send(.lastSevenDays(.task))
        await store.receive(\.lastSevenDays.daysUpdated) {
            $0.lastSevenDays.days = week
        }
        await store.finish()
    }

    /// INSIGHTS-3: the Health data card's actions reach `HealthDataListFeature`, and its state appears under
    /// `healthData`.
    @Test func healthDataActionsReachTheHealthDataListFeature() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeAvailableHealthData = ObserveAvailableHealthDataUseCase(
                repository: FakeHealthDataRepository(availableKinds: { _, _ in [[.sleep]] }))
        }

        await store.send(.healthData(.task))
        await store.receive(\.healthData.kindsUpdated) {
            $0.healthData.available = [.sleep]
        }
        await store.finish()
    }

    /// INSIGHTS-4: tapping the sleep button pushes the Sleep screen onto the tab's navigation stack.
    @Test func tappingSleepPushesTheSleepScreen() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }

        await store.send(.healthData(.kindTapped(.sleep))) {
            $0.path.append(.sleep(SleepDetailFeature.State()))
        }
    }

    /// INSIGHTS-5: tapping the resting heart rate button pushes the resting heart rate screen onto the tab's
    /// navigation stack.
    @Test func tappingRestingHeartRatePushesItsScreen() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }

        await store.send(.healthData(.kindTapped(.restingHeartRate))) {
            $0.path.append(.restingHeartRate(HeartRateDetailFeature.State()))
        }
    }

    /// INSIGHTS-7: "What we noticed"'s actions reach `WhatWeNoticedFeature`, and its state appears under
    /// `whatWeNoticed`.
    @Test func whatWeNoticedActionsReachItsFeature() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        } withDependencies: {
            $0.observeInsightCard = ObserveInsightCardUseCase(
                sleepTolerance: FakeSleepToleranceRepository(analyses: [.empty()]),
                insightFeedback: FakeInsightFeedbackRepository(sets: [[]]),
                languageModel: FakeLanguageModelRepository(availabilities: [.available]))
        }

        await store.send(.whatWeNoticed(.task))
        await store.receive(\.whatWeNoticed.cardUpdated)
        await store.finish()
    }

    /// INSIGHTS-1: the Insights tab's actions reach `InsightsFeature`, and its state appears under `insights`.
    @Test func insightsActionsReachTheInsightsTab() async {
        let window = Self.window
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeSleepWindow = ObserveSleepWindowUseCase(
                repository: FakeCaffeineDecayRepository(sleepWindows: { _ in [window] }))
        }

        await store.send(.insights(.sleepWindow(.task)))
        await store.receive(\.insights.sleepWindow.windowUpdated) {
            $0.insights.sleepWindow.window = Self.window
        }
        await store.finish()
    }
}
