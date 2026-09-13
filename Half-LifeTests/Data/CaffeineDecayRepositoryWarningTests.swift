//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineDecayRepositoryWarningTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live decay repository's cutoff warning stream against WARNREPO-1 to WARNREPO-3 in the Caffeine Cutoff
/// article, with a fake drink log, half-life, absorption rate, bedtime, threshold, and clock. The clock stands at
/// 3:00pm unless a test says otherwise. The time limit turns a value that never arrives into a failure instead of a
/// hang.
@Suite(.timeLimit(.minutes(1)))
struct CaffeineDecayRepositoryWarningTests {

    let rule = CaffeineCutoffRule()

    static let now = date(15)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// Two espresso shots in a latte, 125.4 mg: with nothing logged, its cutoff is 1:00pm.
    static let latte = FavouriteDrink(type: .latte, quantity: 2)
    static let oneShot = FavouriteDrink(type: .latte, quantity: 1)
    static let greenTea = FavouriteDrink(type: .greenTea, quantity: 1)

    static func date(_ hours: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: hours * 3_600)
    }

    static func drink(_ type: DrinkType, quantity: Int, hours: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
            consumedAt: date(hours))
    }

    static func repository(
        _ source: FakeDrinkLogDataSource, now: Date = now, minutes: [Date] = []
    ) -> LiveCaffeineDecayRepository {
        LiveCaffeineDecayRepository(
            drinkLog: source,
            halfLife: FakeHalfLifeDataSource(value: .standard),
            absorption: FakeAbsorptionRateDataSource(value: .standard),
            bedtime: FakeBedtimeDataSource(value: .standard),
            clock: FakeClockDataSource(date: now, minuteDates: minutes),
            threshold: FakeSleepThresholdDataSource(value: .standard))
    }

    func expected(
        _ drink: FavouriteDrink, secondsAgo: TimeInterval = 0, after drinks: [LoggedDrink] = [], now: Date = now
    ) -> CutoffWarning? {
        let inputs = CaffeineCutoffRule.Inputs(
            drink: drink, intakes: drinks.map(\.intake), kinetics: .standard, threshold: .standard, bedtime: .standard)
        return rule.warning(inputs, consumedAt: now.addingTimeInterval(-secondsAgo), calendar: Self.utc)
    }

    // MARK: - WARNREPO-1: a new subscriber gets the warning for the drink, at its time, for the current time

    /// A latte now, at 3:00pm, is two hours past its cutoff.
    @Test func aNewSubscriberGetsTheWarningForTheDrinkNow() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource())

        var warnings = repository.cutoffWarning(for: Self.latte, secondsAgo: 0, in: Self.utc).makeAsyncIterator()

        let received = try #require(await warnings.next())
        #expect(received != nil)
        #expect(received == expected(Self.latte))
    }

    /// The same latte four hours ago, at 11:00am, fits.
    @Test func aDrinkEarlierThanItsCutoffGetsNoWarning() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource())

        var warnings = repository.cutoffWarning(for: Self.latte, secondsAgo: 14_400, in: Self.utc)
            .makeAsyncIterator()

        #expect(try #require(await warnings.next()) == nil)
    }

    // MARK: - WARNREPO-2: after a change to the drink log that alters it, the subscriber gets the new warning

    /// One shot now fits on its own, but not after two cold brews at 2:00pm.
    @Test func theWarningFollowsAChangeToTheDrinkLog() async throws {
        let source = FakeDrinkLogDataSource()
        let repository = Self.repository(source)
        var warnings = repository.cutoffWarning(for: Self.oneShot, secondsAgo: 0, in: Self.utc).makeAsyncIterator()
        #expect(try #require(await warnings.next()) == nil)

        let coldBrews = Self.drink(.coldBrew, quantity: 2, hours: 14)
        await source.insert(coldBrews)
        await source.signalChange()

        let received = try #require(await warnings.next())
        #expect(received != nil)
        #expect(received == expected(Self.oneShot, after: [coldBrews]))
    }

    // MARK: - WARNREPO-3: at each minute, a new warning only if it changed

    /// At 9:00pm a green tea fits. From 9:27pm it wouldn't peak by 10:30pm, so the next warning is the one at 9:30pm.
    @Test func theWarningChangesAtAMinuteOnlyWhenItChanges() async throws {
        let minutes = [Self.date(21 + 10.0 / 60), Self.date(21 + 20.0 / 60), Self.date(21.5)]
        let repository = Self.repository(FakeDrinkLogDataSource(), now: Self.date(21), minutes: minutes)
        var warnings = repository.cutoffWarning(for: Self.greenTea, secondsAgo: 0, in: Self.utc).makeAsyncIterator()
        #expect(try #require(await warnings.next()) == nil)

        #expect(try #require(await warnings.next()) == .stillRisingAtBedtime(bedtime: Self.date(22.5)))
    }
}
