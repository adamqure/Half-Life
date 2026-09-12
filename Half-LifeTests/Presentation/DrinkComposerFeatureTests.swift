//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkComposerFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the drink composer's reducer against the Drink Composer article: requirements COMP-1 to COMP-11.
@MainActor
struct DrinkComposerFeatureTests {

    struct StoreFailed: Error {}

    let now = Date(timeIntervalSinceReferenceDate: 0)

    func drink(_ type: DrinkType, quantity: Int, minutesAgo: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
            consumedAt: now.addingTimeInterval(-minutesAgo * 60))
    }

    // MARK: - COMP-10: the composer opens on the last drink logged, or on espresso

    @Test func opensOnOneEspressoShot() {
        let state = DrinkComposerFeature.State()

        #expect(state.selectedDrink == .espresso)
        #expect(state.quantity == 1)
        #expect(state.consumedWhen == .now)
    }

    @Test func taskChoosesTheLastDrinkLogged() async {
        let older = drink(.cola, quantity: 1, minutesAgo: 120)
        let latest = drink(.latte, quantity: 3, minutesAgo: 10)
        let store = TestStore(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.observeLoggedDrinks = ObserveLoggedDrinksUseCase(
                repository: FakeDrinkLogRepository(drinks: [[older, latest]]))
        }

        await store.send(.task)
        await store.receive(\.loggedDrinksUpdated) {
            $0.selectedDrink = .latte
            $0.quantity = 3
        }
        await store.finish()
    }

    @Test func taskKeepsEspressoWhenNothingIsLogged() async {
        let store = TestStore(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.observeLoggedDrinks = ObserveLoggedDrinksUseCase(repository: FakeDrinkLogRepository(drinks: [[]]))
        }

        await store.send(.task)
        await store.receive(\.loggedDrinksUpdated)
        await store.finish()
    }

    // MARK: - COMP-11: the last drink logged never replaces the user's own choice

    @Test func theLastDrinkLoggedDoesntReplaceAChoice() async {
        let store = TestStore(
            initialState: DrinkComposerFeature.State(selectedDrink: .matcha, quantity: 1, hasChosen: true)
        ) {
            DrinkComposerFeature()
        }

        await store.send(.loggedDrinksUpdated([drink(.latte, quantity: 2, minutesAgo: 5)]))
    }

    // MARK: - COMP-1: choosing a drink starts at its default quantity

    @Test func choosingADrinkStartsAtItsDefaultQuantity() async {
        let store = TestStore(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        }

        await store.send(.drinkSelected(.latte)) {
            $0.selectedDrink = .latte
            $0.quantity = 2
            $0.hasChosen = true
        }
        await store.send(.drinkSelected(.cola)) {
            $0.selectedDrink = .cola
            $0.quantity = 1
        }
    }

    // MARK: - COMP-2: the stepper changes the quantity, never below 1

    @Test func stepperChangesTheQuantityButNeverBelowOne() async {
        let store = TestStore(initialState: DrinkComposerFeature.State(selectedDrink: .espresso, quantity: 1)) {
            DrinkComposerFeature()
        }

        await store.send(.quantityIncremented) {
            $0.quantity = 2
            $0.hasChosen = true
        }
        await store.send(.quantityDecremented) {
            $0.quantity = 1
        }
        await store.send(.quantityDecremented)
    }

    // MARK: - COMP-3: "When" sets how long ago the drink was consumed

    @Test func choosingWhenSetsHowLongAgo() async {
        let store = TestStore(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        }

        await store.send(.consumedWhenSelected(.twoHoursAgo)) {
            $0.consumedWhen = .twoHoursAgo
        }
    }

    @Test(
        arguments: [(.now, 0), (.oneHourAgo, 3_600), (.twoHoursAgo, 7_200), (.fourHoursAgo, 14_400)]
            as [(DrinkComposerFeature.ConsumedWhen, TimeInterval)])
    func eachWhenIsSecondsAgo(when: DrinkComposerFeature.ConsumedWhen, secondsAgo: TimeInterval) {
        #expect(when.secondsAgo == secondsAgo)
    }

    @Test func whenListsItsChoicesInOrder() {
        #expect(DrinkComposerFeature.ConsumedWhen.allCases == [.now, .oneHourAgo, .twoHoursAgo, .fourHoursAgo])
    }

    // MARK: - COMP-4: the estimate is the chosen drink × quantity

    @Test func estimateIsTheChosenDrinkTimesItsQuantity() {
        #expect(DrinkComposerFeature.State().estimatedMilligrams == DrinkType.espresso.estimatedMilligrams(quantity: 1))
        #expect(
            DrinkComposerFeature.State(selectedDrink: .latte, quantity: 3).estimatedMilligrams
                == DrinkType.latte.estimatedMilligrams(quantity: 3))
    }

    // MARK: - COMP-5: Add logs the drink, then the composer closes

    @Test func addingLogsTheDrinkThenCloses() async {
        let drinkLog = FakeDrinkLogRepository()
        let dismissed = LockIsolated(false)
        let store = TestStore(
            initialState: DrinkComposerFeature.State(selectedDrink: .latte, quantity: 3, consumedWhen: .oneHourAgo)
        ) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(currentTime: FakeCurrentTimeRepository(date: now), drinkLog: drinkLog)
            $0.dismiss = DismissEffect { dismissed.setValue(true) }
        }

        await store.send(.addTapped) {
            $0.isLogging = true
        }
        await store.receive(\.logSucceeded) {
            $0.isLogging = false
        }
        await store.finish()

        let logged = await drinkLog.logged
        #expect(logged.map(\.type) == [.latte])
        #expect(logged.map(\.quantity) == [3])
        #expect(logged.map(\.consumedAt) == [now.addingTimeInterval(-3_600)])
        #expect(dismissed.value)
    }

    // MARK: - COMP-6: a failed Add shows the error and stays open

    @Test func aFailedAddShowsTheErrorAndStaysOpen() async {
        let dismissed = LockIsolated(false)
        let store = TestStore(initialState: DrinkComposerFeature.State(selectedDrink: .matcha, quantity: 1)) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(
                currentTime: FakeCurrentTimeRepository(date: now),
                drinkLog: FakeDrinkLogRepository(logError: StoreFailed()))
            $0.dismiss = DismissEffect { dismissed.setValue(true) }
        }

        await store.send(.addTapped) {
            $0.isLogging = true
        }
        await store.receive(\.logFailed) {
            $0.isLogging = false
            $0.saveFailed = true
        }
        await store.finish()

        #expect(!dismissed.value)
    }

    // MARK: - COMP-7: trying again, or choosing another drink, clears the error

    @Test func choosingAnotherDrinkClearsTheError() async {
        let store = TestStore(
            initialState: DrinkComposerFeature.State(selectedDrink: .matcha, quantity: 1, saveFailed: true)
        ) {
            DrinkComposerFeature()
        }

        await store.send(.drinkSelected(.greenTea)) {
            $0.selectedDrink = .greenTea
            $0.hasChosen = true
            $0.saveFailed = false
        }
    }

    @Test func tryingAgainClearsTheError() async {
        let store = TestStore(
            initialState: DrinkComposerFeature.State(selectedDrink: .cola, quantity: 1, saveFailed: true)
        ) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(
                currentTime: FakeCurrentTimeRepository(date: now), drinkLog: FakeDrinkLogRepository())
            $0.dismiss = DismissEffect {}
        }

        await store.send(.addTapped) {
            $0.isLogging = true
            $0.saveFailed = false
        }
        await store.receive(\.logSucceeded) {
            $0.isLogging = false
        }
    }

    // MARK: - COMP-8: Add does nothing while a drink is being logged

    @Test func addDoesNothingWhileLogging() async {
        let store = TestStore(
            initialState: DrinkComposerFeature.State(selectedDrink: .cola, quantity: 1, isLogging: true)
        ) {
            DrinkComposerFeature()
        }

        await store.send(.addTapped)
    }

    // MARK: - COMP-9: Close closes the composer without logging

    @Test func closeClosesTheComposer() async {
        let dismissed = LockIsolated(false)
        let store = TestStore(initialState: DrinkComposerFeature.State(selectedDrink: .latte, quantity: 2)) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { dismissed.setValue(true) }
        }

        await store.send(.closeTapped)
        await store.finish()

        #expect(dismissed.value)
    }
}
