//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveCaffeineDecayRepositoryStatusTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live decay repository's status stream against REPO-6 to REPO-10 in the Caffeine Decay Model article,
/// with a fake drink log, half-life, absorption rate, bedtime, and clock. The time limit turns a status that never
/// arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveCaffeineDecayRepositoryStatusTests {

    let rule = CaffeineStatusRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    /// 4:00pm on the worked examples' day.
    static let afternoon = date(16)
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

    /// The worked examples' day of drinks: 128 mg at 8:00am, 64 mg at 10:45am, and 205 mg at 3:00pm.
    static let dayOfDrinks = [drink(128, hours: 8), drink(64, hours: 10.75), drink(205, hours: 15)]

    static func repository(
        _ source: FakeDrinkLogDataSource, minutes: [Date] = [], absorption: CaffeineAbsorptionRate = .standard,
        bedtime: Bedtime = .standard
    ) -> LiveCaffeineDecayRepository {
        LiveCaffeineDecayRepository(
            drinkLog: source,
            halfLife: FakeHalfLifeDataSource(value: .standard),
            absorption: FakeAbsorptionRateDataSource(value: absorption),
            bedtime: FakeBedtimeDataSource(value: bedtime),
            clock: FakeClockDataSource(date: afternoon, minuteDates: minutes))
    }

    func expected(
        _ drinks: [LoggedDrink], now: Date = afternoon, absorption: CaffeineAbsorptionRate = .standard,
        bedtime: Bedtime = .standard, calendar: Calendar = utc
    ) -> CaffeineStatus {
        rule.status(
            from: drinks.map(\.intake), kinetics: CaffeineKinetics(halfLife: .standard, absorption: absorption),
            bedtime: bedtime, now: now, calendar: calendar)
    }

    // MARK: - REPO-7: a new subscriber gets a status for the current time

    @Test func newSubscriberGetsAStatusForTheCurrentTime() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks))

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        let status = try #require(await statuses.next())

        #expect(status == expected(Self.dayOfDrinks))
    }

    @Test func calculatesWithOnlyTheDrinksThatArentMarkedNegligible() async throws {
        let marked = Self.drink(200, hours: 15.5)
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks + [marked], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        let status = try #require(await statuses.next())

        #expect(status == expected(Self.dayOfDrinks))
        #expect(await source.drinksCallCount == 0)
    }

    // MARK: - REPO-8: a new status at every minute the clock streams

    @Test func publishesAStatusForEveryMinuteTheClockStreams() async throws {
        let minutes = [Self.afternoon.addingTimeInterval(60), Self.afternoon.addingTimeInterval(120)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks), minutes: minutes)

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        _ = try #require(await statuses.next())
        let first = try #require(await statuses.next())
        let second = try #require(await statuses.next())

        #expect(first == expected(Self.dayOfDrinks, now: minutes[0]))
        #expect(second == expected(Self.dayOfDrinks, now: minutes[1]))
    }

    // MARK: - REPO-9: a recalculated status when the drink log changes

    @Test func publishesARecalculatedStatusWhenTheDrinkLogChanges() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks)
        let repository = Self.repository(source)

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        _ = try #require(await statuses.next())
        let late = Self.drink(128, hours: 15.5)
        await source.insert(late)
        await source.signalChange()
        let updated = try #require(await statuses.next())

        #expect(updated == expected(Self.dayOfDrinks + [late]))
    }

    // MARK: - REPO-10: the bedtime from its data source, in the subscriber's calendar

    @Test func usesTheBedtimeFromItsDataSourceInTheGivenCalendar() async throws {
        let bedtime = try #require(Bedtime(hour: 21, minute: 15))
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks), bedtime: bedtime)

        var statuses = repository.status(in: tokyo).makeAsyncIterator()
        let status = try #require(await statuses.next())

        #expect(status == expected(Self.dayOfDrinks, bedtime: bedtime, calendar: tokyo))
    }

    // MARK: - REPO-6: the absorption rate from its data source

    @Test func calculatesTheStatusWithTheAbsorptionRateFromItsDataSource() async throws {
        let oneHour = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_600))
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks), absorption: oneHour)

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        let status = try #require(await statuses.next())

        #expect(status == expected(Self.dayOfDrinks, absorption: oneHour))
        #expect(status != expected(Self.dayOfDrinks))
    }
}
