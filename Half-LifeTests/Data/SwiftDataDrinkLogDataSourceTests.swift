//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SwiftDataDrinkLogDataSourceTests
//

import Foundation
import SwiftData
import Testing

@testable import Half_Life

extension SwiftDataStoreTests {

    /// Checks the SwiftData drink log against DATA-1 to DATA-5 in the Caffeine Decay Model article, and SRC-1,
    /// SRC-3, and SRC-4 in the Drink Composer article. Each test uses its own in-memory store, with CloudKit off.
    /// It runs inside the serialized `SwiftDataStoreTests`, because it opens stores.
    @Suite struct SwiftDataDrinkLogDataSourceTests {

        let container: ModelContainer
        let source: SwiftDataDrinkLogDataSource

        init() throws {
            container = try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: true)
            source = SwiftDataDrinkLogDataSource(modelContainer: container)
        }

        static let midnight = Date(timeIntervalSinceReferenceDate: 0)

        static func drink(_ type: DrinkType = .espresso, milligrams: Double = 64, hours: Double) -> LoggedDrink {
            LoggedDrink(
                type: type, quantity: 1, milligrams: milligrams,
                consumedAt: midnight.addingTimeInterval(hours * 3_600))
        }

        /// Counts the signals `changes` delivers for `work`. Signals are buffered, so after a short wait every
        /// signal the work sent has been counted, and cancelling ends the count.
        static func signalCount(
            _ changes: AsyncStream<Void>, during work: () async throws -> Void
        ) async throws -> Int {
            let counter = Task {
                var count = 0
                for await _ in changes {
                    count += 1
                }
                return count
            }
            try await work()
            try await Task.sleep(for: .milliseconds(200))
            counter.cancel()
            return await counter.value
        }

        @Test func storedDrinkComesBackWithEveryField() async throws {
            let drink = LoggedDrink(
                type: .coldBrew, quantity: 2, milligrams: 410,
                consumedAt: Self.midnight.addingTimeInterval(8 * 3_600))

            try await source.store(drink)

            #expect(try await source.drinks() == [drink])
        }

        @Test func drinksComeBackOldestFirst() async throws {
            let later = Self.drink(hours: 15)
            let earlier = Self.drink(hours: 8)

            try await source.store(later)
            try await source.store(earlier)

            #expect(try await source.drinks() == [earlier, later])
        }

        /// DATA-4.
        @Test func newDrinkIsStoredUnmarked() async throws {
            let drink = Self.drink(hours: 8)

            try await source.store(drink)

            #expect(try await source.nonNegligibleDrinks() == [drink])
        }

        /// DATA-1 and SRC-4.
        @Test func markedDrinksAreLeftOutOfTheActiveQuery() async throws {
            let old = Self.drink(hours: 0)
            let recent = Self.drink(hours: 40)
            try await source.store(old)
            try await source.store(recent)

            try await source.markNegligible([old.intake])

            #expect(try await source.nonNegligibleDrinks() == [recent])
        }

        @Test func markingNoIntakesChangesNothing() async throws {
            let drink = Self.drink(hours: 8)
            try await source.store(drink)

            try await source.markNegligible([])

            #expect(try await source.nonNegligibleDrinks() == [drink])
        }

        /// DATA-3.
        @Test func markingNeverDeletesADrink() async throws {
            let old = Self.drink(hours: 0)
            let recent = Self.drink(hours: 40)
            try await source.store(old)
            try await source.store(recent)

            try await source.markNegligible([old.intake])

            #expect(try await source.drinks() == [old, recent])
        }

        /// DATA-2: a second data source over the same store still sees the mark.
        @Test func marksPersistInTheStore() async throws {
            let old = Self.drink(hours: 0)
            try await source.store(old)

            try await source.markNegligible([old.intake])

            let reopened = SwiftDataDrinkLogDataSource(modelContainer: container)
            #expect(try await reopened.nonNegligibleDrinks().isEmpty)
        }

        /// DATA-5 and SRC-1.
        @Test func everySubscriberGetsOneSignalPerStore() async throws {
            let first = await source.changes()
            let second = await source.changes()

            let firstCount = try await Self.signalCount(first) {
                try await source.store(Self.drink(hours: 8))
                try await source.store(Self.drink(hours: 9))
            }
            let secondCount = try await Self.signalCount(second) {}

            #expect(firstCount == 2)
            #expect(secondCount == 2)
        }

        /// DATA-5 and SRC-3.
        @Test func markingSignalsNothing() async throws {
            let old = Self.drink(hours: 0)
            try await source.store(old)
            let changes = await source.changes()

            let count = try await Self.signalCount(changes) {
                try await source.markNegligible([old.intake])
            }

            #expect(count == 0)
        }

        /// A drink whose stored type this version doesn't know, for example from a newer version synced through
        /// CloudKit, is left out rather than failing the whole read.
        @Test func drinkWithAnUnknownTypeIsSkipped() async throws {
            let context = ModelContext(container)
            context.insert(
                DrinkRecord(
                    id: UUID(), typeRawValue: "unknownDrink", quantity: 1, milligrams: 50, consumedAt: .now))
            try context.save()
            let known = Self.drink(hours: 8)
            try await source.store(known)

            #expect(try await source.drinks() == [known])
            #expect(try await source.nonNegligibleDrinks() == [known])
        }
    }
}
