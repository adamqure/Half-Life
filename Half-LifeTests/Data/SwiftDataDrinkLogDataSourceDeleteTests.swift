//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SwiftDataDrinkLogDataSourceDeleteTests
//

import Foundation
import SwiftData
import Testing

@testable import Half_Life

extension SwiftDataStoreTests {

    /// Checks deleting from the SwiftData drink log against SRC-5 to SRC-7 in the Drink Composer article. Each test
    /// uses its own in-memory store, with CloudKit off. It runs inside the serialized `SwiftDataStoreTests`, because it
    /// opens stores.
    @Suite struct SwiftDataDrinkLogDataSourceDeleteTests {

        let container: ModelContainer
        let source: SwiftDataDrinkLogDataSource

        init() throws {
            container = try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: true)
            source = SwiftDataDrinkLogDataSource(modelContainer: container)
        }

        static func drink(hours: Double) -> LoggedDrink {
            SwiftDataDrinkLogDataSourceTests.drink(hours: hours)
        }

        // MARK: - SRC-5: deleting removes the drink, marked or not, from the store

        @Test func deletingADrinkRemovesItAndKeepsTheOthers() async throws {
            let kept = Self.drink(hours: 8)
            let deleted = Self.drink(hours: 9)
            try await source.store(kept)
            try await source.store(deleted)

            try await source.delete(deleted.id)

            #expect(try await source.drinks() == [kept])
            #expect(try await source.nonNegligibleDrinks() == [kept])
        }

        @Test func deletingAMarkedDrinkRemovesIt() async throws {
            let marked = Self.drink(hours: 0)
            try await source.store(marked)
            try await source.markNegligible([marked.intake])

            try await source.delete(marked.id)

            #expect(try await source.drinks().isEmpty)
        }

        @Test func aDeletionPersistsInTheStore() async throws {
            let drink = Self.drink(hours: 8)
            try await source.store(drink)

            try await source.delete(drink.id)

            let reopened = SwiftDataDrinkLogDataSource(modelContainer: container)
            #expect(try await reopened.drinks().isEmpty)
        }

        // MARK: - SRC-6: every subscriber gets one signal after each deletion

        @Test func everySubscriberGetsOneSignalPerDeletion() async throws {
            let drink = Self.drink(hours: 8)
            try await source.store(drink)
            let first = await source.changes()
            let second = await source.changes()

            let firstCount = try await SwiftDataDrinkLogDataSourceTests.signalCount(first) {
                try await source.delete(drink.id)
            }
            let secondCount = try await SwiftDataDrinkLogDataSourceTests.signalCount(second) {}

            #expect(firstCount == 1)
            #expect(secondCount == 1)
        }

        // MARK: - SRC-7: deleting a drink that isn't stored changes nothing and signals nothing

        @Test func deletingADrinkThatIsntStoredChangesNothingAndSignalsNothing() async throws {
            let drink = Self.drink(hours: 8)
            try await source.store(drink)
            let changes = await source.changes()

            let count = try await SwiftDataDrinkLogDataSourceTests.signalCount(changes) {
                try await source.delete(UUID())
            }

            #expect(count == 0)
            #expect(try await source.drinks() == [drink])
        }
    }
}
