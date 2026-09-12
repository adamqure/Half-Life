//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveFavouriteDrinksRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live favourites repository against FAVREPO-1 to FAVREPO-3 in the One-Tap Log article, with a fake drink
/// log data source. The time limit turns favourites that never arrive into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveFavouriteDrinksRepositoryTests {

    struct DataSourceFailed: Error {}

    static let now = Date(timeIntervalSinceReferenceDate: 100_000)

    static func drink(_ type: DrinkType, _ quantity: Int, minutesAgo: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
            consumedAt: now.addingTimeInterval(-minutesAgo * 60))
    }

    static func favourite(_ type: DrinkType, _ quantity: Int) -> FavouriteDrink {
        FavouriteDrink(type: type, quantity: quantity)
    }

    /// Waits until the repository is listening to the data source's changes, so a signal can't be missed.
    static func waitUntilListening(_ source: FakeDrinkLogDataSource) async {
        while await source.subscriberCount == 0 {
            await Task.yield()
        }
    }

    // MARK: - FAVREPO-1: a new subscriber gets the favourites of every drink, then new ones after each change

    @Test func newSubscriberGetsTheFavouritesOfEveryDrinkHeld() async throws {
        let source = FakeDrinkLogDataSource(drinks: [
            Self.drink(.cola, 1, minutesAgo: 60), Self.drink(.matcha, 1, minutesAgo: 10),
            Self.drink(.cola, 1, minutesAgo: 30),
        ])
        let repository = LiveFavouriteDrinksRepository(dataSource: source)

        var favourites = repository.favourites().makeAsyncIterator()

        #expect(
            try #require(await favourites.next())
                == [Self.favourite(.cola, 1), Self.favourite(.matcha, 1), Self.favourite(.espresso, 2)])
    }

    @Test func countsDrinksMarkedNegligibleToo() async throws {
        let old = [Self.drink(.cola, 1, minutesAgo: 3_000), Self.drink(.cola, 1, minutesAgo: 2_900)]
        let recent = Self.drink(.matcha, 1, minutesAgo: 10)
        let source = FakeDrinkLogDataSource(drinks: old + [recent], negligibleIDs: Set(old.map(\.id)))
        let repository = LiveFavouriteDrinksRepository(dataSource: source)

        var favourites = repository.favourites().makeAsyncIterator()

        #expect(try #require(await favourites.next()).first == Self.favourite(.cola, 1))
        #expect(await source.nonNegligibleDrinksCallCount == 0)
    }

    @Test func everySubscriberGetsNewFavouritesAfterAChange() async throws {
        let source = FakeDrinkLogDataSource(drinks: [Self.drink(.matcha, 1, minutesAgo: 60)])
        let repository = LiveFavouriteDrinksRepository(dataSource: source)
        var one = repository.favourites().makeAsyncIterator()
        var two = repository.favourites().makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()

        await source.insert(Self.drink(.cola, 1, minutesAgo: 20))
        await source.insert(Self.drink(.cola, 1, minutesAgo: 10))
        await source.signalChange()

        let expected = [Self.favourite(.cola, 1), Self.favourite(.matcha, 1), Self.favourite(.espresso, 2)]
        #expect(try #require(await one.next()) == expected)
        #expect(try #require(await two.next()) == expected)
    }

    @Test func listensToTheDataSourceOnceForEverySubscriber() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = LiveFavouriteDrinksRepository(dataSource: source)
        var one = repository.favourites().makeAsyncIterator()
        var two = repository.favourites().makeAsyncIterator()

        _ = await one.next()
        _ = await two.next()

        #expect(await source.subscriberCount == 1)
    }

    // MARK: - FAVREPO-2: with nothing logged, it publishes the starters

    @Test func withNothingLoggedItPublishesTheStarters() async throws {
        let repository = LiveFavouriteDrinksRepository(dataSource: FakeDrinkLogDataSource())

        var favourites = repository.favourites().makeAsyncIterator()

        #expect(try #require(await favourites.next()) == FavouriteDrinksRule.starters)
    }

    // MARK: - FAVREPO-3: a failed read publishes nothing, and the next change recovers

    @Test func failedReadPublishesNothingAndTheNextChangeRecovers() async throws {
        let source = FakeDrinkLogDataSource(drinks: [Self.drink(.matcha, 1, minutesAgo: 30)])
        await source.failReads(with: DataSourceFailed())
        let repository = LiveFavouriteDrinksRepository(dataSource: source)
        var favourites = repository.favourites().makeAsyncIterator()
        await Self.waitUntilListening(source)

        await source.failReads(with: nil)
        await source.signalChange()

        #expect(try #require(await favourites.next()).first == Self.favourite(.matcha, 1))
    }
}
