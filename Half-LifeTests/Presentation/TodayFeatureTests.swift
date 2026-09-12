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

/// Checks that the Today screen composes its cards (TODAY-1 and TODAY-2 in the Today Screen article).
@MainActor
struct TodayFeatureTests {

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
}
