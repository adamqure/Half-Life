//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests TodayFeatureHistoryTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the Today screen composes the history card (TODAY-4 in the Today Screen article).
@MainActor
struct TodayFeatureHistoryTests {

    /// TODAY-4: the history card's actions reach `DrinkLogHistoryFeature`, and its state appears under `history`.
    @Test func historyActionsReachTheHistoryFeature() async {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let noon = Date(timeIntervalSinceReferenceDate: 12 * 3_600)
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.calendar = utc
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: FakeCurrentTimeRepository(date: noon))
            $0.observeDrinkLogDay = ObserveDrinkLogDayUseCase(repository: FakeDrinkLogRepository())
        }

        await store.send(.history(.task))
        await store.receive(\.history.timeOfDayUpdated) {
            $0.history.today = Date(timeIntervalSinceReferenceDate: 0)
            $0.history.selectedDay = Date(timeIntervalSinceReferenceDate: 0)
        }
        await store.finish()
    }
}
