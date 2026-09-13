//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveDrinkLogRepositoryRecentDaysTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live drink log repository's recent days stream against RECENTREPO-1 to RECENTREPO-4 in the Insights
/// article, with a fake drink log data source and a fake clock stopped at 4:00pm. The time limit turns days that never
/// arrive into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveDrinkLogRepositoryRecentDaysTests {

    let rule = DrinkLogDayRule()

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

    /// A cup two days ago at 9:00pm, then 128 mg at 8:00am and 64 mg at 10:45am today.
    static let drinks = [drink(64, hours: -27), drink(128, hours: 8), drink(64, hours: 10.75)]

    static func repository(_ source: FakeDrinkLogDataSource, minutes: [Date] = []) -> LiveDrinkLogRepository {
        LiveDrinkLogRepository(dataSource: source, clock: FakeClockDataSource(date: date(16), minuteDates: minutes))
    }

    /// Waits until the repository is listening to the data source's changes, so a signal can't be missed.
    static func waitUntilListening(_ source: FakeDrinkLogDataSource) async {
        while await source.subscriberCount == 0 {
            await Task.yield()
        }
    }

    func expected(_ drinks: [LoggedDrink], at now: Date = date(16), count: Int = 7) -> [DrinkLogDay] {
        rule.days(endingOn: now, count: count, from: drinks, calendar: Self.utc)
    }

    // MARK: - RECENTREPO-1: a new subscriber gets the days up to the current day

    @Test func newSubscriberGetsTheDaysUpToTheCurrentDay() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks))

        var days = repository.recentDays(7, in: Self.utc).makeAsyncIterator()

        #expect(try #require(await days.next()) == expected(Self.drinks))
    }

    /// The days count every drink, including the ones the decay repository marked negligible.
    @Test func countsDrinksMarkedNegligibleToo() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks, negligibleIDs: [Self.drinks[0].id])
        let repository = Self.repository(source)

        var days = repository.recentDays(3, in: Self.utc).makeAsyncIterator()

        #expect(try #require(await days.next()) == expected(Self.drinks, count: 3))
    }

    // MARK: - RECENTREPO-2: after a change that alters the days, a subscriber gets the new ones

    @Test func aSubscriberGetsTheNewDaysAfterAChange() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var days = repository.recentDays(7, in: Self.utc).makeAsyncIterator()
        _ = await days.next()
        await Self.waitUntilListening(source)

        let added = Self.drink(95, hours: -50)
        await source.insert(added)
        await source.signalChange()

        #expect(try #require(await days.next()) == expected(Self.drinks + [added]))
    }

    /// A change outside the days, such as a drink from a month ago, sends nothing, so the next days received are the
    /// next real change's.
    @Test func aChangeOutsideTheDaysSendsNothing() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.drinks)
        let repository = Self.repository(source)
        var days = repository.recentDays(7, in: Self.utc).makeAsyncIterator()
        _ = await days.next()
        await Self.waitUntilListening(source)

        let monthAgo = Self.drink(95, hours: -30 * 24)
        await source.insert(monthAgo)
        await source.signalChange()
        let yesterday = Self.drink(64, hours: -10)
        await source.insert(yesterday)
        await source.signalChange()

        #expect(try #require(await days.next()) == expected(Self.drinks + [monthAgo, yesterday]))
    }

    // MARK: - RECENTREPO-3: the days move on at the first minute of a new day, and only then

    @Test func theDaysMoveOnAtTheFirstMinuteOfANewDay() async throws {
        let minutes = [Self.date(16).addingTimeInterval(60), Self.date(24)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks), minutes: minutes)

        var days = repository.recentDays(7, in: Self.utc).makeAsyncIterator()

        #expect(try #require(await days.next()) == expected(Self.drinks))
        #expect(try #require(await days.next()) == expected(Self.drinks, at: Self.date(24)))
    }

    // MARK: - RECENTREPO-4: each subscriber gets its own count, in its own calendar

    @Test func eachSubscriberGetsItsOwnCountInItsOwnCalendar() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.drinks))

        var week = repository.recentDays(7, in: Self.utc).makeAsyncIterator()
        var twoInTokyo = repository.recentDays(2, in: tokyo).makeAsyncIterator()

        #expect(try #require(await week.next()) == expected(Self.drinks))
        #expect(
            try #require(await twoInTokyo.next())
                == rule.days(endingOn: Self.date(16), count: 2, from: Self.drinks, calendar: tokyo))
    }
}
