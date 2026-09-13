//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataListFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data buttons card against HCARD4-1 to HCARD4-3 in the Insights article.
@MainActor
struct HealthDataListFeatureTests {

    /// HCARD4-1: `task` subscribes to the available kinds in the calendar dependency, and each set is reduced into
    /// `State`.
    @Test func taskReducesEachSetOfKindsInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeHealthDataRepository(availableKinds: { days, calendar in
            days == 30 && calendar.timeZone == tokyoTimeZone ? [[.steps], [.sleep, .steps]] : []
        })
        let store = TestStore(initialState: HealthDataListFeature.State()) {
            HealthDataListFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeAvailableHealthData = ObserveAvailableHealthDataUseCase(repository: repository)
        }

        await store.send(.task)
        await store.receive(\.kindsUpdated) {
            $0.available = [.steps]
        }
        await store.receive(\.kindsUpdated) {
            $0.available = [.sleep, .steps]
        }
        await store.finish()
    }

    /// HCARD4-2: the buttons are the available kinds, in their fixed order, and the card shows only when there's one.
    @Test func theButtonsAreTheAvailableKindsInOrder() {
        #expect(HealthDataListFeature.State().kinds.isEmpty)
        #expect(!HealthDataListFeature.State().isShown)
        let state = HealthDataListFeature.State(available: [.restingHeartRate, .sleep])
        #expect(state.kinds == [.sleep, .restingHeartRate])
        #expect(state.isShown)
    }
}
