//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveDrinkLogRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live drink log repository against DLOG-1 to DLOG-4 in the Drink Composer article, with a fake drink
/// log data source and a stopped clock. The time limit turns a set of drinks that never arrives into a failure
/// instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveDrinkLogRepositoryTests {

    struct DataSourceFailed: Error {}

    static let now = Date(timeIntervalSinceReferenceDate: 100_000)

    static func drink(
        _ type: DrinkType = .espresso, quantity: Int = 1, milligrams: Double = 62.7, minutesAgo: Double
    ) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: milligrams, consumedAt: now.addingTimeInterval(-minutesAgo * 60)
        )
    }

    static func repository(_ source: FakeDrinkLogDataSource) -> LiveDrinkLogRepository {
        LiveDrinkLogRepository(dataSource: source, clock: FakeClockDataSource(date: now, minuteDates: []))
    }

    /// Waits until the repository is listening to the data source's changes, so a signal can't be missed.
    static func waitUntilListening(_ source: FakeDrinkLogDataSource) async {
        while await source.subscriberCount == 0 {
            await Task.yield()
        }
    }

    // MARK: - DLOG-1: a new subscriber gets every drink, then the updated set after each change

    @Test func newSubscriberGetsEveryDrinkOldestFirst() async throws {
        let early = Self.drink(minutesAgo: 120)
        let late = Self.drink(minutesAgo: 10)
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: [late, early]))

        var drinks = repository.loggedDrinks().makeAsyncIterator()

        #expect(try #require(await drinks.next()) == [early, late])
    }

    @Test func publishesDrinksMarkedNegligibleToo() async throws {
        let marked = Self.drink(minutesAgo: 3_000)
        let recent = Self.drink(minutesAgo: 10)
        let source = FakeDrinkLogDataSource(drinks: [marked, recent], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var drinks = repository.loggedDrinks().makeAsyncIterator()

        #expect(try #require(await drinks.next()) == [marked, recent])
        #expect(await source.nonNegligibleDrinksCallCount == 0)
    }

    @Test func everySubscriberGetsTheUpdatedSetAfterAChange() async throws {
        let first = Self.drink(minutesAgo: 60)
        let source = FakeDrinkLogDataSource(drinks: [first])
        let repository = Self.repository(source)
        var one = repository.loggedDrinks().makeAsyncIterator()
        var two = repository.loggedDrinks().makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()

        let second = Self.drink(minutesAgo: 5)
        await source.insert(second)
        await source.signalChange()

        #expect(try #require(await one.next()) == [first, second])
        #expect(try #require(await two.next()) == [first, second])
    }

    @Test func listensToTheDataSourceOnceForEverySubscriber() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = Self.repository(source)
        var one = repository.loggedDrinks().makeAsyncIterator()
        var two = repository.loggedDrinks().makeAsyncIterator()

        _ = await one.next()
        _ = await two.next()

        #expect(await source.subscriberCount == 1)
    }

    // MARK: - DLOG-2: log(_:) stores through the data source, and a failed store publishes nothing

    @Test func loggingStoresTheDrinkThenPublishesTheUpdatedSet() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        #expect(try #require(await drinks.next()) == [])

        let drink = Self.drink(minutesAgo: 1)
        try await repository.log(drink)

        #expect(await source.heldDrinks == [drink])
        #expect(try #require(await drinks.next()) == [drink])
    }

    @Test func aFailedStoreThrowsAndPublishesNothing() async throws {
        let source = FakeDrinkLogDataSource(storeError: DataSourceFailed())
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        _ = await drinks.next()

        await #expect(throws: DataSourceFailed.self) {
            try await repository.log(Self.drink(minutesAgo: 1))
        }

        // The next set published is the one after this later change, so the failed store published nothing.
        let later = Self.drink(minutesAgo: 2)
        await source.insert(later)
        await source.signalChange()
        #expect(try #require(await drinks.next()) == [later])
    }

    // MARK: - DLOG-3: a drink keeps the milligrams it was logged with

    @Test func aDrinkComesBackWithTheMilligramsItWasLoggedWith() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        _ = await drinks.next()

        // 128 mg, not the catalog's 125.4 mg for two shots.
        try await repository.log(Self.drink(.latte, quantity: 2, milligrams: 128, minutesAgo: 1))

        #expect(try #require(await drinks.next()).map(\.milligrams) == [128])
    }

    // MARK: - DLOG-4: log(_:) executes DrinkLogRule with the current time

    @Test func aDrinkConsumedInTheFutureIsRejectedAndNotStored() async {
        let source = FakeDrinkLogDataSource()

        await #expect(throws: DrinkLogRule.Violation.consumedInFuture) {
            try await Self.repository(source).log(Self.drink(minutesAgo: -1))
        }
        #expect(await source.heldDrinks.isEmpty)
    }

    @Test func aQuantityBelowOneIsRejectedAndNotStored() async {
        let source = FakeDrinkLogDataSource()

        await #expect(throws: DrinkLogRule.Violation.quantityBelowOne) {
            try await Self.repository(source).log(Self.drink(quantity: 0, milligrams: 0, minutesAgo: 1))
        }
        #expect(await source.heldDrinks.isEmpty)
    }

    @Test func aDrinkConsumedExactlyNowIsStored() async throws {
        let source = FakeDrinkLogDataSource()
        let drink = Self.drink(minutesAgo: 0)

        try await Self.repository(source).log(drink)

        #expect(await source.heldDrinks == [drink])
    }

    // MARK: - Failures

    /// A failed read publishes nothing, and the next change, once the drinks can be read, publishes the set.
    @Test func failedReadPublishesNothingAndTheNextChangeRecovers() async throws {
        let drink = Self.drink(minutesAgo: 30)
        let source = FakeDrinkLogDataSource(drinks: [drink])
        await source.failReads(with: DataSourceFailed())
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        await Self.waitUntilListening(source)

        await source.failReads(with: nil)
        await source.signalChange()

        #expect(try #require(await drinks.next()) == [drink])
    }
}
