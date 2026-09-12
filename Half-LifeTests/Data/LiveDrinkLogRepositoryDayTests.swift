//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveDrinkLogRepositoryDayTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live drink log repository's day stream and deletion against DAYLOG-1 to DAYLOG-3 and DELETE-1 to
/// DELETE-2 in the Today Screen article, with a fake drink log data source and a fake clock stopped at 4:00pm. The time
/// limit turns a day that never arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveDrinkLogRepositoryDayTests {

    struct DataSourceFailed: Error {}

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func drink(_ milligrams: Double, hours: Double) -> LoggedDrink {
        LoggedDrink(type: .espresso, quantity: 1, milligrams: milligrams, consumedAt: date(hours))
    }

    /// A cup at 10:00pm yesterday, then 128 mg at 8:00am and 64 mg at 10:45am today.
    static let yesterday = drink(95, hours: -2)
    static let morning = drink(128, hours: 8)
    static let lateMorning = drink(64, hours: 10.75)
    static let drinks = [yesterday, morning, lateMorning]

    static let today = DrinkLogDay(
        intake: DailyCaffeineIntake(day: midnight, milligrams: 192), drinks: [morning, lateMorning])

    static func repository(_ source: FakeDrinkLogDataSource) -> LiveDrinkLogRepository {
        LiveDrinkLogRepository(dataSource: source, clock: FakeClockDataSource(date: date(16), minuteDates: []))
    }

    /// Waits until the repository is listening to the data source's changes, so a signal can't be missed.
    static func waitUntilListening(_ source: FakeDrinkLogDataSource) async {
        while await source.subscriberCount == 0 {
            await Task.yield()
        }
    }

    // MARK: - DAYLOG-1: a new subscriber gets the day it asked for, in its calendar

    @Test func newSubscriberGetsTheDayContainingTheDateItGives() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks))

        var days = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()

        #expect(try #require(await days.next()) == Self.today)
    }

    @Test func aSubscriberCanAskForAPastDay() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks))

        var days = repository.day(containing: Self.date(-12), in: Self.utc).makeAsyncIterator()

        let yesterday = DrinkLogDay(
            intake: DailyCaffeineIntake(day: Self.date(-24), milligrams: 95), drinks: [Self.yesterday])
        #expect(try #require(await days.next()) == yesterday)
    }

    @Test func includesDrinksMarkedNegligible() async throws {
        let marked = Self.drink(40, hours: 9)
        let source = FakeDrinkLogDataSource(drinks: Self.drinks + [marked], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var days = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()

        let day = try #require(await days.next())
        #expect(day.drinks == [Self.morning, marked, Self.lateMorning])
        #expect(await source.nonNegligibleDrinksCallCount == 0)
    }

    /// At noon UTC it's 9:00pm in Tokyo, on a day that started at 3:00pm UTC yesterday, so all three drinks are on it.
    @Test func findsTheDayInTheSubscribersCalendar() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks))

        var days = repository.day(containing: Self.date(12), in: tokyo).makeAsyncIterator()

        let day = try #require(await days.next())
        #expect(day.intake == DailyCaffeineIntake(day: Self.date(-9), milligrams: 287))
        #expect(day.drinks == Self.drinks)
    }

    // MARK: - DAYLOG-2: after a change that alters its day, every subscriber gets the new day

    @Test func everySubscriberOfTheDayGetsTheNewDayAfterAChange() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var one = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()
        var two = repository.day(containing: Self.date(20), in: Self.utc).makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()

        let afternoon = Self.drink(205, hours: 15)
        await source.insert(afternoon)
        await source.signalChange()

        let updated = DrinkLogDay(
            intake: DailyCaffeineIntake(day: Self.midnight, milligrams: 397),
            drinks: [Self.morning, Self.lateMorning, afternoon])
        #expect(try #require(await one.next()) == updated)
        #expect(try #require(await two.next()) == updated)
    }

    @Test func aChangeThatLeavesTheDayAlonePublishesNothing() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var days = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()
        _ = await days.next()

        await source.insert(Self.drink(80, hours: -5))
        await source.signalChange()
        let afternoon = Self.drink(205, hours: 15)
        await source.insert(afternoon)
        await source.signalChange()

        // The next day published is the one after the second change, so the change to yesterday published nothing.
        #expect(try #require(await days.next()).drinks == [Self.morning, Self.lateMorning, afternoon])
    }

    // MARK: - DAYLOG-3: one subscription to the data source serves every stream

    @Test func listensToTheDataSourceOnceForEveryStream() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        var days = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()

        _ = await drinks.next()
        _ = await intakes.next()
        _ = await days.next()

        #expect(await source.subscriberCount == 1)
    }

    /// A failed read publishes nothing, and the next change, once the drinks can be read, publishes the day.
    @Test func failedReadPublishesNothingAndTheNextChangeRecovers() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        await source.failReads(with: DataSourceFailed())
        let repository = Self.repository(source)
        var days = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()
        await Self.waitUntilListening(source)

        await source.failReads(with: nil)
        await source.signalChange()

        #expect(try #require(await days.next()) == Self.today)
    }

    // MARK: - DELETE-1: deleting has the data source delete the drink, and its change is published

    @Test func deletingHasTheDataSourceDeleteTheDrinkThenPublishesTheChange() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        var days = repository.day(containing: Self.date(12), in: Self.utc).makeAsyncIterator()
        _ = await drinks.next()
        _ = await days.next()

        try await repository.delete(Self.morning.id)

        let withoutMorning = DrinkLogDay(
            intake: DailyCaffeineIntake(day: Self.midnight, milligrams: 64), drinks: [Self.lateMorning])
        #expect(await source.heldDrinks == [Self.yesterday, Self.lateMorning])
        #expect(try #require(await drinks.next()) == [Self.yesterday, Self.lateMorning])
        #expect(try #require(await days.next()) == withoutMorning)
    }

    // MARK: - DELETE-2: a failed deletion throws and publishes nothing

    @Test func aFailedDeletionThrowsAndPublishesNothing() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        await source.failDeletes(with: DataSourceFailed())
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        _ = await drinks.next()

        await #expect(throws: DataSourceFailed.self) {
            try await repository.delete(Self.morning.id)
        }

        // The next set published is the one after this later change, so the failed deletion published nothing.
        let later = Self.drink(205, hours: 15)
        await source.insert(later)
        await source.signalChange()
        #expect(try #require(await drinks.next()) == Self.drinks + [later])
    }
}
