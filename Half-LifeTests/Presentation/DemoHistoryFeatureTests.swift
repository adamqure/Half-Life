//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoHistoryFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks Settings' demo history section against SETDEMO-1 to SETDEMO-4 in the Settings article.
@MainActor
struct DemoHistoryFeatureTests {

    struct ChangeFailed: Error {}

    static let newYork: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: -4 * 3_600) ?? .gmt
        return calendar
    }()

    // MARK: - SETDEMO-1: the section shows whether the log holds demo drinks, from the repository

    @Test func taskReducesWhetherTheLogHoldsDemoDrinks() async {
        let store = TestStore(initialState: DemoHistoryFeature.State()) {
            DemoHistoryFeature()
        } withDependencies: {
            $0.observeDemoHistory = ObserveDemoHistoryUseCase(
                drinkLog: FakeDrinkLogRepository(hasDemoHistory: [false, true]))
        }

        await store.send(.task)
        await store.receive(\.demoHistoryUpdated) {
            $0.hasDemoHistory = false
        }
        await store.receive(\.demoHistoryUpdated) {
            $0.hasDemoHistory = true
        }
        await store.finish()
    }

    // MARK: - SETDEMO-2: adding and removing go through their use cases, and the answer waits for the repository

    @Test func addingAddsTheDemoHistoryInTheUsersCalendar() async {
        let drinkLog = FakeDrinkLogRepository()
        let store = TestStore(initialState: DemoHistoryFeature.State(hasDemoHistory: false)) {
            DemoHistoryFeature()
        } withDependencies: {
            $0.calendar = Self.newYork
            $0.addDemoHistory = AddDemoHistoryUseCase(drinkLog: drinkLog)
        }

        await store.send(.addTapped) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
        }

        #expect(await drinkLog.demoHistoryAdded == [Self.newYork])
    }

    @Test func removingRemovesTheDemoHistory() async {
        let drinkLog = FakeDrinkLogRepository()
        let store = TestStore(initialState: DemoHistoryFeature.State(hasDemoHistory: true)) {
            DemoHistoryFeature()
        } withDependencies: {
            $0.removeDemoHistory = RemoveDemoHistoryUseCase(drinkLog: drinkLog)
        }

        await store.send(.removeTapped) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
        }

        #expect(await drinkLog.demoHistoryRemovedCount == 1)
    }

    // MARK: - SETDEMO-3: a failed change says so, until the next try

    @Test func aFailedChangeSaysSoUntilTheNextTry() async {
        let store = TestStore(initialState: DemoHistoryFeature.State(hasDemoHistory: false)) {
            DemoHistoryFeature()
        } withDependencies: {
            $0.calendar = Self.newYork
            $0.addDemoHistory = AddDemoHistoryUseCase(
                drinkLog: FakeDrinkLogRepository(demoHistoryError: ChangeFailed()))
        }

        await store.send(.addTapped) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
            $0.changeFailed = true
        }
        await store.send(.addTapped) {
            $0.isChanging = true
            $0.changeFailed = false
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
            $0.changeFailed = true
        }
    }

    // MARK: - SETDEMO-4: a tap while a change is under way does nothing

    @Test func tappingWhileAChangeIsUnderWayDoesNothing() async {
        let store = TestStore(initialState: DemoHistoryFeature.State(hasDemoHistory: true, isChanging: true)) {
            DemoHistoryFeature()
        }

        await store.send(.addTapped)
        await store.send(.removeTapped)
    }
}
