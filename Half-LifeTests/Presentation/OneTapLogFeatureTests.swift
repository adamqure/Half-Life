//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests OneTapLogFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the one-tap row's reducer against the One-Tap Log article: requirements ONETAP-1 to ONETAP-6.
@MainActor
struct OneTapLogFeatureTests {

    struct StoreFailed: Error {}

    let now = Date(timeIntervalSinceReferenceDate: 0)
    let latte = FavouriteDrink(type: .latte, quantity: 2)
    let cola = FavouriteDrink(type: .cola, quantity: 1)

    // MARK: - ONETAP-1: the favourites are observed and reduced into State

    @Test func taskObservesTheFavourites() async {
        let first = FavouriteDrinksRule.starters
        let second = [latte] + FavouriteDrinksRule.starters.prefix(2)
        let store = TestStore(initialState: OneTapLogFeature.State()) {
            OneTapLogFeature()
        } withDependencies: {
            $0.observeFavouriteDrinks = ObserveFavouriteDrinksUseCase(
                repository: FakeFavouriteDrinksRepository(sets: [first, second]))
        }

        await store.send(.task)
        await store.receive(\.favouritesUpdated) {
            $0.favourites = first
        }
        await store.receive(\.favouritesUpdated) {
            $0.favourites = second
        }
        await store.finish()
    }

    // MARK: - ONETAP-2 and ONETAP-3: a tap logs the favourite now, then confirms it for 2 seconds and tells the parent

    @Test func aTapLogsTheFavouriteNowThenConfirmsIt() async {
        let drinkLog = FakeDrinkLogRepository()
        let clock = TestClock()
        let store = TestStore(initialState: OneTapLogFeature.State(favourites: [latte, cola])) {
            OneTapLogFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(currentTime: FakeCurrentTimeRepository(date: now), drinkLog: drinkLog)
            $0.continuousClock = clock
        }

        await store.send(.favouriteTapped(latte)) {
            $0.logging = latte
        }
        await store.receive(\.logSucceeded) {
            $0.logging = nil
            $0.justLogged = latte
        }
        await store.receive(\.delegate.drinkLogged)
        await clock.advance(by: .seconds(1))
        await clock.advance(by: .seconds(1))
        await store.receive(\.confirmationEnded) {
            $0.justLogged = nil
        }

        let logged = await drinkLog.logged
        #expect(logged.map(\.type) == [.latte])
        #expect(logged.map(\.quantity) == [2])
        #expect(logged.map(\.consumedAt) == [now])
    }

    @Test func theConfirmationLastsTwoSeconds() {
        #expect(OneTapLogFeature.confirmationDuration == .seconds(2))
    }

    // MARK: - ONETAP-4: a failed log shows the error, and the next tap clears it

    @Test func aFailedLogShowsTheErrorWithoutAConfirmation() async {
        let store = TestStore(initialState: OneTapLogFeature.State(favourites: [latte])) {
            OneTapLogFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(
                currentTime: FakeCurrentTimeRepository(date: now),
                drinkLog: FakeDrinkLogRepository(logError: StoreFailed()))
        }

        await store.send(.favouriteTapped(latte)) {
            $0.logging = latte
        }
        await store.receive(\.logFailed) {
            $0.logging = nil
            $0.saveFailed = true
        }
    }

    @Test func theNextTapClearsTheError() async {
        let store = TestStore(initialState: OneTapLogFeature.State(favourites: [latte], saveFailed: true)) {
            OneTapLogFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(
                currentTime: FakeCurrentTimeRepository(date: now),
                drinkLog: FakeDrinkLogRepository(logError: StoreFailed()))
        }

        await store.send(.favouriteTapped(latte)) {
            $0.logging = latte
            $0.saveFailed = false
        }
        await store.receive(\.logFailed) {
            $0.logging = nil
            $0.saveFailed = true
        }
    }

    // MARK: - ONETAP-5: a tap does nothing while a drink is being logged

    @Test func aTapDoesNothingWhileADrinkIsBeingLogged() async {
        let store = TestStore(initialState: OneTapLogFeature.State(favourites: [latte, cola], logging: latte)) {
            OneTapLogFeature()
        }

        await store.send(.favouriteTapped(cola))
    }

    // MARK: - ONETAP-6: another log during a confirmation moves the confirmation to it, and restarts it

    @Test func anotherLogMovesAndRestartsTheConfirmation() async {
        let drinkLog = FakeDrinkLogRepository()
        let clock = TestClock()
        let store = TestStore(initialState: OneTapLogFeature.State(favourites: [latte, cola])) {
            OneTapLogFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(currentTime: FakeCurrentTimeRepository(date: now), drinkLog: drinkLog)
            $0.continuousClock = clock
        }

        await store.send(.favouriteTapped(latte)) {
            $0.logging = latte
        }
        await store.receive(\.logSucceeded) {
            $0.logging = nil
            $0.justLogged = latte
        }
        await store.receive(\.delegate.drinkLogged)
        await clock.advance(by: .seconds(1.5))

        await store.send(.favouriteTapped(cola)) {
            $0.logging = cola
        }
        await store.receive(\.logSucceeded) {
            $0.logging = nil
            $0.justLogged = cola
        }
        await store.receive(\.delegate.drinkLogged)
        // The latte's confirmation would have ended here. The cola's still has 1.5 seconds to go.
        await clock.advance(by: .seconds(0.5))
        await clock.advance(by: .seconds(1.5))
        await store.receive(\.confirmationEnded) {
            $0.justLogged = nil
        }

        #expect(await drinkLog.logged.map(\.type) == [.latte, .cola])
    }
}
