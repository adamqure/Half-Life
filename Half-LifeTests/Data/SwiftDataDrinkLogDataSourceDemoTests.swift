//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SwiftDataDrinkLogDataSourceDemoTests
//

import Foundation
import SwiftData
import Testing

@testable import Half_Life

extension SwiftDataStoreTests {

    /// Checks the SwiftData drink log's demo drinks against SRC-8 to SRC-10 in the Settings article. Each test uses its
    /// own in-memory store, with CloudKit off. It runs inside the serialized `SwiftDataStoreTests`, because it opens
    /// stores.
    @Suite struct SwiftDataDrinkLogDataSourceDemoTests {

        let container: ModelContainer
        let source: SwiftDataDrinkLogDataSource

        init() throws {
            container = try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: true)
            source = SwiftDataDrinkLogDataSource(modelContainer: container)
        }

        static func drink(hours: Double, isDemo: Bool = false) -> LoggedDrink {
            LoggedDrink(
                type: .latte, quantity: 2, milligrams: 125.4,
                consumedAt: SwiftDataDrinkLogDataSourceTests.midnight.addingTimeInterval(hours * 3_600), isDemo: isDemo)
        }

        // MARK: - SRC-8: a drink keeps whether it's a demo drink

        @Test func aDemoDrinkKeepsItsMarkAndTheUsersOwnHasNone() async throws {
            let own = Self.drink(hours: 8)
            let demo = Self.drink(hours: 9, isDemo: true)

            try await source.store(own)
            try await source.store(demo)

            #expect(try await source.drinks() == [own, demo])
        }

        // MARK: - SRC-9: replacing the demo drinks keeps the user's own, and stores the new ones marked demo

        @Test func replacingTheDemoDrinksKeepsTheUsersOwn() async throws {
            let own = Self.drink(hours: 8)
            let oldDemo = Self.drink(hours: 9, isDemo: true)
            try await source.store(own)
            try await source.store(oldDemo)
            let newDemo = [Self.drink(hours: 7), Self.drink(hours: 10)]

            try await source.replaceDemoDrinks(with: newDemo)

            let drinks = try await source.drinks()
            #expect(drinks.map(\.id) == [newDemo[0].id, own.id, newDemo[1].id])
            #expect(drinks.map(\.isDemo) == [true, false, true])
        }

        @Test func replacingSignalsOnce() async throws {
            try await source.store(Self.drink(hours: 9, isDemo: true))
            let changes = await source.changes()

            let count = try await SwiftDataDrinkLogDataSourceTests.signalCount(changes) {
                try await source.replaceDemoDrinks(with: [Self.drink(hours: 7), Self.drink(hours: 10)])
            }

            #expect(count == 1)
        }

        @Test func aReplacementPersistsInTheStore() async throws {
            try await source.store(Self.drink(hours: 9, isDemo: true))
            let newDemo = Self.drink(hours: 10)

            try await source.replaceDemoDrinks(with: [newDemo])

            let reopened = SwiftDataDrinkLogDataSource(modelContainer: container)
            #expect(try await reopened.drinks().map(\.id) == [newDemo.id])
        }

        // MARK: - SRC-10: removing the demo drinks when there are none changes nothing and signals nothing

        @Test func removingWhenThereAreNoDemoDrinksSignalsNothing() async throws {
            let own = Self.drink(hours: 8)
            try await source.store(own)
            let changes = await source.changes()

            let count = try await SwiftDataDrinkLogDataSourceTests.signalCount(changes) {
                try await source.replaceDemoDrinks(with: [])
            }

            #expect(count == 0)
            #expect(try await source.drinks() == [own])
        }

        @Test func removingTheDemoDrinksSignalsOnceAndLeavesTheUsersOwn() async throws {
            let own = Self.drink(hours: 8)
            try await source.store(own)
            try await source.store(Self.drink(hours: 9, isDemo: true))
            try await source.store(Self.drink(hours: 10, isDemo: true))
            let changes = await source.changes()

            let count = try await SwiftDataDrinkLogDataSourceTests.signalCount(changes) {
                try await source.replaceDemoDrinks(with: [])
            }

            #expect(count == 1)
            #expect(try await source.drinks() == [own])
        }
    }
}
