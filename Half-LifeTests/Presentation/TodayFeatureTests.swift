//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests TodayFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the Today screen composes its cards (TODAY-1 to TODAY-3 in the Today Screen article).
@MainActor
struct TodayFeatureTests {

    /// TODAY-LASTCUP: the "Last cup" tile's actions reach `LastCupFeature`, and its state appears under `lastCup`.
    @Test func lastCupActionsReachTheLastCupFeature() async {
        let cutoff = CaffeineCutoff(
            drink: FavouriteDrink(type: .latte, quantity: 2), latestCup: nil,
            bedtime: Date(timeIntervalSinceReferenceDate: 22.5 * 3_600), threshold: .standard)
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeCaffeineCutoff = ObserveCaffeineCutoffUseCase(
                repository: FakeCaffeineDecayRepository(cutoffs: { _ in [cutoff] }))
        }

        await store.send(.lastCup(.task))
        await store.receive(\.lastCup.cutoffUpdated) {
            $0.lastCup.cutoff = cutoff
        }
        await store.finish()
    }

    /// TODAY-3: the "Today" tile's actions reach `CaffeineIntakeTodayFeature`, and its state appears under
    /// `caffeineIntakeToday`.
    @Test func caffeineIntakeTodayActionsReachTheIntakeFeature() async {
        let intake = DailyCaffeineIntake(day: Date(timeIntervalSinceReferenceDate: 0), milligrams: 192)
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeCaffeineIntakeToday = ObserveCaffeineIntakeTodayUseCase(
                repository: FakeDrinkLogRepository(intakes: { _ in [intake] }))
        }

        await store.send(.caffeineIntakeToday(.task))
        await store.receive(\.caffeineIntakeToday.intakeUpdated) {
            $0.caffeineIntakeToday.intake = intake
        }
        await store.finish()
    }

    /// TODAY-2: the decay card's actions reach `CaffeineDecayFeature`, and its state appears under `caffeineDecay`.
    @Test func caffeineDecayActionsReachTheDecayFeature() async {
        let curve = [CaffeineLevel(date: Date(timeIntervalSinceReferenceDate: 0), milligrams: 85)]
        let repository = FakeCaffeineDecayRepository(curves: [curve])
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeCaffeineCurve = ObserveCaffeineCurveUseCase(repository: repository)
            $0.observeCaffeineStatus = ObserveCaffeineStatusUseCase(repository: repository)
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: SilentCurrentTimeRepository())
        }

        await store.send(.caffeineDecay(.task))
        await store.receive(\.caffeineDecay.curveUpdated) {
            $0.caffeineDecay.curve = curve
        }
        await store.finish()
    }

    /// TODAY-1: the greeting's actions reach `DailyGreetingFeature`, and its state appears under `greeting`.
    @Test func greetingActionsReachTheGreetingFeature() async {
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [UserProfile(name: "Alex")])
            )
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: SilentCurrentTimeRepository())
        }

        await store.send(.greeting(.task))
        await store.receive(\.greeting.profileUpdated) {
            $0.greeting.name = "Alex"
        }
        await store.finish()
    }

    /// ONETAP-7 in the One-Tap Log article: the one-tap row's actions reach `OneTapLogFeature`, and its state appears
    /// under `oneTapLog`.
    @Test func oneTapActionsReachTheOneTapFeature() async {
        let favourites = FavouriteDrinksRule.starters
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.observeFavouriteDrinks = ObserveFavouriteDrinksUseCase(
                repository: FakeFavouriteDrinksRepository(sets: [favourites]))
        }

        await store.send(.oneTapLog(.task))
        await store.receive(\.oneTapLog.favouritesUpdated) {
            $0.oneTapLog.favourites = favourites
        }
        await store.finish()
    }
}
