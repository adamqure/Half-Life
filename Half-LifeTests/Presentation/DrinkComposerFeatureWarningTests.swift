//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkComposerFeatureWarningTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the drink composer's cutoff warning against WARNCOMP-1 to WARNCOMP-3 in the Drink Composer article, with the
/// warning's use case built on a fake decay repository.
@MainActor
struct DrinkComposerFeatureWarningTests {

    let now = Date(timeIntervalSinceReferenceDate: 0)

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    static let bedtime = Date(timeIntervalSinceReferenceDate: 22.5 * 3_600)
    static let tooMuch = CutoffWarning.tooMuchAtBedtime(
        level: CaffeineLevel(date: bedtime, milligrams: 51), threshold: .standard)
    static let stillRising = CutoffWarning.stillRisingAtBedtime(bedtime: bedtime)

    // MARK: - WARNCOMP-1: `task` observes the warning for the chosen drink, quantity, and time

    @Test func taskObservesTheWarningForTheChosenDrink() async {
        let repository = FakeCaffeineDecayRepository(warnings: { drink, secondsAgo, calendar in
            drink == FavouriteDrink(type: .espresso, quantity: 1) && secondsAgo == 0 && calendar == Self.utc
                ? [Self.stillRising] : []
        })
        let store = TestStore(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.observeLoggedDrinks = ObserveLoggedDrinksUseCase(repository: FakeDrinkLogRepository())
            $0.observeCutoffWarning = ObserveCutoffWarningUseCase(repository: repository)
        }

        await store.send(.task)
        await store.receive(\.cutoffWarningUpdated) {
            $0.cutoffWarning = Self.stillRising
        }
        await store.finish()
    }

    // MARK: - WARNCOMP-2: changing the drink, the quantity, or the time observes the new choice's warning

    @Test func changingTheChoiceObservesItsWarning() async {
        let repository = FakeCaffeineDecayRepository(warnings: { drink, secondsAgo, _ in
            guard drink.type == .latte else { return [] }
            switch (drink.quantity, secondsAgo) {
            case (2, 0): return [Self.tooMuch]
            case (2, 14_400): return [nil]
            case (3, 14_400): return [Self.stillRising]
            default: return []
            }
        })
        let store = TestStore(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.observeCutoffWarning = ObserveCutoffWarningUseCase(repository: repository)
        }

        await store.send(.drinkSelected(.latte)) {
            $0.selectedDrink = .latte
            $0.quantity = 2
            $0.hasChosen = true
        }
        await store.receive(\.cutoffWarningUpdated) {
            $0.cutoffWarning = Self.tooMuch
        }
        await store.send(.consumedWhenSelected(.fourHoursAgo)) {
            $0.consumedWhen = .fourHoursAgo
        }
        await store.receive(\.cutoffWarningUpdated) {
            $0.cutoffWarning = nil
        }
        await store.send(.quantityIncremented) {
            $0.quantity = 3
        }
        await store.receive(\.cutoffWarningUpdated) {
            $0.cutoffWarning = Self.stillRising
        }
        await store.finish()
    }

    // MARK: - WARNCOMP-3: a warning never stops Add

    @Test func aWarningDoesntStopAdd() async {
        let drinkLog = FakeDrinkLogRepository()
        let store = TestStore(
            initialState: DrinkComposerFeature.State(selectedDrink: .latte, quantity: 2, cutoffWarning: Self.tooMuch)
        ) {
            DrinkComposerFeature()
        } withDependencies: {
            $0.logDrink = LogDrinkUseCase(currentTime: FakeCurrentTimeRepository(date: now), drinkLog: drinkLog)
            $0.dismiss = DismissEffect {}
        }

        await store.send(.addTapped) {
            $0.isLogging = true
        }
        await store.receive(\.logSucceeded) {
            $0.isLogging = false
        }
        await store.finish()

        #expect(await drinkLog.logged.map(\.type) == [.latte])
    }
}
