//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveDrinkLogRepositoryIntakeTodayTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live drink log repository's intake stream against DLOG-5 to DLOG-9 in the Today Screen article, with a
/// fake drink log data source and a fake clock stopped at 4:00pm. The time limit turns an intake that never arrives
/// into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveDrinkLogRepositoryIntakeTodayTests {

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

    /// A cup at 10:00pm yesterday, then 128 mg at 8:00am and 64 mg at 10:45am today: 192 mg today.
    static let drinks = [drink(95, hours: -2), drink(128, hours: 8), drink(64, hours: 10.75)]

    static let today = DailyCaffeineIntake(day: midnight, milligrams: 192)

    static func repository(_ source: FakeDrinkLogDataSource, minutes: [Date] = []) -> LiveDrinkLogRepository {
        LiveDrinkLogRepository(dataSource: source, clock: FakeClockDataSource(date: date(16), minuteDates: minutes))
    }

    /// Waits until the repository is listening to the data source's changes, so a signal can't be missed.
    static func waitUntilListening(_ source: FakeDrinkLogDataSource) async {
        while await source.subscriberCount == 0 {
            await Task.yield()
        }
    }

    // MARK: - DLOG-5: a new subscriber gets the intake for the current day

    @Test func newSubscriberGetsTheIntakeForTheCurrentDay() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks))

        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()

        #expect(try #require(await intakes.next()) == Self.today)
    }

    @Test func countsDrinksMarkedNegligibleToo() async throws {
        let marked = Self.drink(40, hours: 9)
        let source = FakeDrinkLogDataSource(drinks: Self.drinks + [marked], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()

        #expect(try #require(await intakes.next()) == DailyCaffeineIntake(day: Self.midnight, milligrams: 232))
    }

    // MARK: - DLOG-6: after a change that alters the day's total, every subscriber gets the new intake

    @Test func everySubscriberGetsTheNewIntakeAfterAChange() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var one = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        var two = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()

        await source.insert(Self.drink(205, hours: 15))
        await source.signalChange()

        let updated = DailyCaffeineIntake(day: Self.midnight, milligrams: 397)
        #expect(try #require(await one.next()) == updated)
        #expect(try #require(await two.next()) == updated)
    }

    @Test func aChangeThatLeavesTheDaysTotalAlonePublishesNothing() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        _ = await intakes.next()

        await source.insert(Self.drink(80, hours: -5))
        await source.signalChange()
        await source.insert(Self.drink(205, hours: 15))
        await source.signalChange()

        // The next intake published is the one after the second change, so the change to yesterday published nothing.
        #expect(try #require(await intakes.next()) == DailyCaffeineIntake(day: Self.midnight, milligrams: 397))
    }

    // MARK: - DLOG-7: at the first minute of a new day, the new day's intake

    @Test func publishesTheNewDaysIntakeAtTheMinuteTheDayTurns() async throws {
        let minutes = [Self.date(16).addingTimeInterval(60), Self.date(16).addingTimeInterval(120), Self.date(24)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks), minutes: minutes)

        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        _ = try #require(await intakes.next())

        // The minutes before midnight leave the day's total alone, so the next intake is the new day's.
        #expect(try #require(await intakes.next()) == DailyCaffeineIntake(day: Self.date(24), milligrams: 0))
    }

    // MARK: - DLOG-8: the day is each subscriber's own calendar's

    /// Tokyo's day started at 3:00pm UTC, so only the cup at 3:30pm UTC is on it.
    @Test func findsTheDayInEachSubscribersCalendar() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let source = FakeDrinkLogDataSource(drinks: Self.drinks + [Self.drink(205, hours: 15.5)])
        let repository = Self.repository(source)

        var inUTC = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        var inTokyo = repository.intakeToday(in: tokyo).makeAsyncIterator()

        #expect(try #require(await inUTC.next()) == DailyCaffeineIntake(day: Self.midnight, milligrams: 397))
        #expect(try #require(await inTokyo.next()) == DailyCaffeineIntake(day: Self.date(15), milligrams: 205))
    }

    // MARK: - DLOG-9: one subscription to the data source serves the drinks and the intakes

    @Test func listensToTheDataSourceOnceForTheDrinksAndTheIntakes() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = Self.repository(source)
        var drinks = repository.loggedDrinks().makeAsyncIterator()
        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()

        _ = await drinks.next()
        _ = await intakes.next()

        #expect(await source.subscriberCount == 1)
    }

    // MARK: - Failures

    /// A failed read publishes nothing, and the next change, once the drinks can be read, publishes the intake.
    @Test func failedReadPublishesNothingAndTheNextChangeRecovers() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        await source.failReads(with: DataSourceFailed())
        let repository = Self.repository(source)
        var intakes = repository.intakeToday(in: Self.utc).makeAsyncIterator()
        await Self.waitUntilListening(source)

        await source.failReads(with: nil)
        await source.signalChange()

        #expect(try #require(await intakes.next()) == Self.today)
    }
}
