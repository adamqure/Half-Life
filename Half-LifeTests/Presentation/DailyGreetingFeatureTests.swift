//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DailyGreetingFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the greeting reduces the profile and the time of day it observes (GREET-1 and GREET-2 in the Today
/// Screen article).
///
/// Each test lets only one of the two streams emit, so the order of received actions is deterministic.
@MainActor
struct DailyGreetingFeatureTests {

    /// GREET-1: `task` subscribes to the profile, and each profile's name is reduced into `State`.
    @Test func taskReducesEachProfilesNameIntoState() async {
        let store = TestStore(initialState: DailyGreetingFeature.State()) {
            DailyGreetingFeature()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [UserProfile(name: nil), UserProfile(name: "Alex")])
            )
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: SilentCurrentTimeRepository())
        }

        await store.send(.task)
        await store.receive(\.profileUpdated)
        await store.receive(\.profileUpdated) {
            $0.name = "Alex"
        }
        await store.finish()
    }

    /// GREET-2: `task` subscribes to the time of day, and each time of day is reduced into `State`.
    @Test func taskReducesEachTimeOfDayIntoState() async throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try #require(TimeZone(identifier: "UTC"))
        let afternoon = try #require(utc.date(from: DateComponents(year: 2026, month: 9, day: 11, hour: 15)))
        let store = TestStore(initialState: DailyGreetingFeature.State()) {
            DailyGreetingFeature()
        } withDependencies: {
            $0.calendar = utc
            $0.observeUserProfile = ObserveUserProfileUseCase(repository: FakeUserProfileRepository(profiles: []))
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: FakeCurrentTimeRepository(date: afternoon))
        }

        await store.send(.task)
        await store.receive(\.timeOfDayUpdated) {
            $0.timeOfDay = TimeOfDay(date: afternoon, period: .afternoon)
        }
        await store.finish()
    }
}
