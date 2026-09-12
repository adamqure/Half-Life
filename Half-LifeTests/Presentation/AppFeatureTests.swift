//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the root feature against the Drink Composer article: requirements ROOT-1 to ROOT-3.
@MainActor
struct AppFeatureTests {

    // MARK: - ROOT-1: the log button presents the composer

    @Test func theLogButtonPresentsTheComposer() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.logButtonTapped) {
            $0.composer = DrinkComposerFeature.State()
        }
    }

    // MARK: - ROOT-2: closing the composer dismisses it

    @Test func closingTheComposerDismissesIt() async {
        let store = TestStore(initialState: AppFeature.State(composer: DrinkComposerFeature.State())) {
            AppFeature()
        }

        await store.send(\.composer.closeTapped)
        await store.receive(\.composer.dismiss) {
            $0.composer = nil
        }
    }

    // MARK: - ROOT-3: logging a drink dismisses the composer

    @Test func loggingADrinkDismissesTheComposer() async {
        let drinkLog = FakeDrinkLogRepository()
        let store = TestStore(
            initialState: AppFeature.State(
                composer: DrinkComposerFeature.State(selectedDrink: .espresso, quantity: 1))
        ) {
            AppFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(
                currentTime: FakeCurrentTimeRepository(date: Date(timeIntervalSinceReferenceDate: 0)),
                drinkLog: drinkLog)
        }

        await store.send(\.composer.addTapped) {
            $0.composer?.isLogging = true
        }
        await store.receive(\.composer.logSucceeded) {
            $0.composer?.isLogging = false
        }
        await store.receive(\.composer.dismiss) {
            $0.composer = nil
        }

        #expect(await drinkLog.logged.map(\.type) == [.espresso])
    }
}
