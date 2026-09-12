//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LastCupFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the "Last cup" tile reduces the cutoffs it observes (LASTCUP-1 in the Caffeine Cutoff article).
@MainActor
struct LastCupFeatureTests {

    /// LASTCUP-1: `task` subscribes to the cutoff in the calendar dependency, and each cutoff is reduced into `State`.
    @Test func taskReducesEachCutoffInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let bedtime = Date(timeIntervalSinceReferenceDate: 22.5 * 3_600)
        let latte = FavouriteDrink(type: .latte, quantity: 2)
        let before = CaffeineCutoff(
            drink: latte, latestCup: Date(timeIntervalSinceReferenceDate: 47_160), bedtime: bedtime,
            threshold: .standard)
        let after = CaffeineCutoff(drink: latte, latestCup: nil, bedtime: bedtime, threshold: .standard)
        let repository = FakeCaffeineDecayRepository(cutoffs: { $0.timeZone == tokyoTimeZone ? [before, after] : [] })
        let store = TestStore(initialState: LastCupFeature.State()) {
            LastCupFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeCaffeineCutoff = ObserveCaffeineCutoffUseCase(repository: repository)
        }

        await store.send(.task)
        await store.receive(\.cutoffUpdated) {
            $0.cutoff = before
        }
        await store.receive(\.cutoffUpdated) {
            $0.cutoff = after
        }
        await store.finish()
    }
}
