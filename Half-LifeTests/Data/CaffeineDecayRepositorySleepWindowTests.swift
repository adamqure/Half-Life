//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineDecayRepositorySleepWindowTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live decay repository's sleep window stream against SWREPO-1 to SWREPO-4 in the Insights article, with a
/// fake drink log, half-life, absorption rate, bedtime, threshold, and clock. The clock stands at 9:00am. The time
/// limit turns a window that never arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct CaffeineDecayRepositorySleepWindowTests {

    struct DataSourceFailed: Error {}

    let rule = SleepWindowRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let now = date(9)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func drink(quantity: Int = 1, hours: Double) -> LoggedDrink {
        LoggedDrink(
            type: .latte, quantity: quantity, milligrams: DrinkType.latte.estimatedMilligrams(quantity: quantity),
            consumedAt: date(hours))
    }

    static func repository(
        _ source: FakeDrinkLogDataSource, minutes: [Date] = [], threshold: SleepThreshold = .standard,
        bedtime: Bedtime = .standard
    ) -> LiveCaffeineDecayRepository {
        LiveCaffeineDecayRepository(
            drinkLog: source,
            halfLife: FakeHalfLifeDataSource(value: .standard),
            absorption: FakeAbsorptionRateDataSource(value: .standard),
            bedtime: FakeBedtimeDataSource(value: bedtime),
            clock: FakeClockDataSource(date: now, minuteDates: minutes),
            threshold: FakeSleepThresholdDataSource(value: threshold))
    }

    func expected(
        after drinks: [LoggedDrink], now: Date = now, threshold: SleepThreshold = .standard,
        bedtime: Bedtime = .standard, calendar: Calendar = utc
    ) throws -> SleepWindow {
        let inputs = SleepWindowRule.Inputs(
            intakes: drinks.map(\.intake), kinetics: .standard, threshold: threshold, bedtime: bedtime)
        return try #require(rule.window(inputs, now: now, calendar: calendar))
    }

    // MARK: - SWREPO-1: a new subscriber gets the window for the current time

    @Test func newSubscriberGetsTheWindowForTheCurrentTime() async throws {
        let drinks = [Self.drink(quantity: 2, hours: 8)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks))

        var windows = repository.sleepWindow(in: Self.utc).makeAsyncIterator()

        #expect(try #require(await windows.next()) == expected(after: drinks))
    }

    @Test func usesTheThresholdAndBedtimeFromTheirDataSourcesInTheGivenCalendar() async throws {
        let threshold = try #require(SleepThreshold(milligrams: 25))
        let bedtime = try #require(Bedtime(hour: 21, minute: 0))
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let drinks = [Self.drink(quantity: 2, hours: 1)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks), threshold: threshold, bedtime: bedtime)

        var windows = repository.sleepWindow(in: tokyo).makeAsyncIterator()
        let window = try #require(await windows.next())

        #expect(try window == expected(after: drinks, threshold: threshold, bedtime: bedtime, calendar: tokyo))
        #expect(try window != expected(after: drinks))
    }

    /// The fake marks a latte from 7:00am, which would still count, so including it would change the window. A drink
    /// the decay rule really finds negligible adds nothing to any level, so it couldn't show the difference.
    @Test func onlyTheIntakesThatStillCountAreUsed() async throws {
        let marked = Self.drink(quantity: 2, hours: 7)
        let counting = [Self.drink(quantity: 2, hours: 8)]
        let source = FakeDrinkLogDataSource(drinks: counting + [marked], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var windows = repository.sleepWindow(in: Self.utc).makeAsyncIterator()
        let window = try #require(await windows.next())

        #expect(try window == expected(after: counting))
        #expect(try window != expected(after: counting + [marked]))
    }

    // MARK: - SWREPO-2: after a change, a subscriber gets the window when it differs from the last one sent

    @Test func aSubscriberGetsTheNewWindowAfterAChange() async throws {
        let first = Self.drink(hours: 8)
        let source = FakeDrinkLogDataSource(drinks: [first])
        let repository = Self.repository(source)
        var windows = repository.sleepWindow(in: Self.utc).makeAsyncIterator()
        _ = await windows.next()

        let second = Self.drink(quantity: 3, hours: 8.5)
        await source.insert(second)
        await source.signalChange()

        #expect(try #require(await windows.next()) == expected(after: [first, second]))
    }

    /// A change that leaves the window as it was sends nothing, so the next window received is the next real change's.
    @Test func aChangeThatLeavesTheWindowAsItWasSendsNothing() async throws {
        let first = Self.drink(hours: 8)
        let source = FakeDrinkLogDataSource(drinks: [first])
        let repository = Self.repository(source)
        var windows = repository.sleepWindow(in: Self.utc).makeAsyncIterator()
        _ = await windows.next()

        await source.signalChange()
        let second = Self.drink(quantity: 3, hours: 8.5)
        await source.insert(second)
        await source.signalChange()

        #expect(try #require(await windows.next()) == expected(after: [first, second]))
    }

    // MARK: - SWREPO-3: a minute sends a window only when the night changes, at 4am

    @Test func aMinuteSendsNothingUntilTheNightChanges() async throws {
        let drinks = [Self.drink(quantity: 2, hours: 8)]
        let minutes = [Self.date(9).addingTimeInterval(60), Self.date(28)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks), minutes: minutes)

        var windows = repository.sleepWindow(in: Self.utc).makeAsyncIterator()

        #expect(try #require(await windows.next()) == expected(after: drinks))
        #expect(try #require(await windows.next()) == expected(after: drinks, now: Self.date(28)))
    }

    // MARK: - SWREPO-4: when an input can't be read, nothing is sent

    /// A failed read sends nothing, and the next change, once the drinks can be read, sends the window.
    @Test func aFailedReadSendsNothingAndTheNextChangeRecovers() async throws {
        let drinks = [Self.drink(hours: 8)]
        let source = FakeDrinkLogDataSource(drinks: drinks)
        await source.failReads(with: DataSourceFailed())
        let repository = Self.repository(source)
        var windows = repository.sleepWindow(in: Self.utc).makeAsyncIterator()
        while await source.nonNegligibleDrinksCallCount == 0 {
            await Task.yield()
        }

        await source.failReads(with: nil)
        await source.signalChange()

        #expect(try #require(await windows.next()) == expected(after: drinks))
    }
}
