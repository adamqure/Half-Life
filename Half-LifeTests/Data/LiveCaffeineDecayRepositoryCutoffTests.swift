//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveCaffeineDecayRepositoryCutoffTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live decay repository's cutoff stream against CUTREPO-1 to CUTREPO-4 in the Caffeine Cutoff article,
/// with a fake drink log, half-life, absorption rate, bedtime, threshold, and clock. The clock stands at 9:00am. The
/// time limit turns a cutoff that never arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveCaffeineDecayRepositoryCutoffTests {

    let rule = CaffeineCutoffRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let now = date(9)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// One espresso shot in a latte, 62.7 mg: small enough that a morning of them still leaves a cutoff. After one at
    /// 7:00am, the cutoff is about 4:30pm, and after a second at 8:30am, about 1:00pm.
    static let latte = FavouriteDrink(type: .latte, quantity: 1)

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func drink(_ type: DrinkType = .latte, quantity: Int = 1, hours: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
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
        _ drink: FavouriteDrink, after drinks: [LoggedDrink], now: Date = now, threshold: SleepThreshold = .standard,
        bedtime: Bedtime = .standard, calendar: Calendar = utc
    ) throws -> CaffeineCutoff {
        let inputs = CaffeineCutoffRule.Inputs(
            drink: drink, intakes: drinks.map(\.intake), kinetics: .standard, threshold: threshold, bedtime: bedtime)
        return try #require(rule.cutoff(inputs, now: now, calendar: calendar))
    }

    // MARK: - CUTREPO-1: a new subscriber gets the cutoff for the current time

    @Test func newSubscriberGetsTheCutoffForTheCurrentTime() async throws {
        let drinks = [Self.drink(hours: 8)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks))

        var cutoffs = repository.cutoff(in: Self.utc).makeAsyncIterator()

        #expect(try #require(await cutoffs.next()) == expected(Self.latte, after: drinks))
    }

    @Test func usesTheThresholdAndBedtimeFromTheirDataSourcesInTheGivenCalendar() async throws {
        let threshold = try #require(SleepThreshold(milligrams: 25))
        let bedtime = try #require(Bedtime(hour: 21, minute: 0))
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let drinks = [Self.drink(hours: 1)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks), threshold: threshold, bedtime: bedtime)

        var cutoffs = repository.cutoff(in: tokyo).makeAsyncIterator()
        let cutoff = try #require(await cutoffs.next())

        let inTokyo = try expected(Self.latte, after: drinks, threshold: threshold, bedtime: bedtime, calendar: tokyo)
        #expect(cutoff == inTokyo)
        #expect(try cutoff != expected(Self.latte, after: drinks))
    }

    // MARK: - CUTREPO-2: the usual drink comes from every logged drink; its intakes only from those still counting

    /// Two single colas, one marked negligible, outnumber one latte, so a cola is the usual drink. Only the latte
    /// and the cola that isn't marked count toward the caffeine already in the body.
    @Test func theUsualDrinkCountsDrinksMarkedNegligibleButTheirCaffeineDoesnt() async throws {
        let marked = Self.drink(.cola, quantity: 1, hours: -30)
        let counting = [Self.drink(.cola, quantity: 1, hours: 7), Self.drink(hours: 8)]
        let source = FakeDrinkLogDataSource(drinks: counting + [marked], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var cutoffs = repository.cutoff(in: Self.utc).makeAsyncIterator()

        #expect(
            try #require(await cutoffs.next())
                == expected(FavouriteDrink(type: .cola, quantity: 1), after: counting))
    }

    @Test func withNothingLoggedTheUsualDrinkIsTheFirstStarter() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource())

        var cutoffs = repository.cutoff(in: Self.utc).makeAsyncIterator()

        #expect(try #require(await cutoffs.next()) == expected(FavouriteDrinksRule.starters[0], after: []))
    }

    // MARK: - CUTREPO-3: after a change that alters the cutoff, every subscriber gets the new one

    @Test func everySubscriberGetsTheNewCutoffAfterAChange() async throws {
        let first = Self.drink(hours: 7)
        let source = FakeDrinkLogDataSource(drinks: [first])
        let repository = Self.repository(source)
        var one = repository.cutoff(in: Self.utc).makeAsyncIterator()
        var two = repository.cutoff(in: Self.utc).makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()

        let second = Self.drink(hours: 8.5)
        await source.insert(second)
        await source.signalChange()

        let updated = try expected(Self.latte, after: [first, second])
        #expect(try #require(await one.next()) == updated)
        #expect(try #require(await two.next()) == updated)
    }

    /// A latte from three days ago adds nothing at bedtime and doesn't change the usual drink.
    @Test func aChangeThatLeavesTheCutoffAlonePublishesNothing() async throws {
        let first = Self.drink(hours: 7)
        let source = FakeDrinkLogDataSource(drinks: [first])
        let repository = Self.repository(source)
        var cutoffs = repository.cutoff(in: Self.utc).makeAsyncIterator()
        _ = await cutoffs.next()

        let longAgo = Self.drink(hours: -72)
        await source.insert(longAgo)
        await source.signalChange()
        let second = Self.drink(hours: 8.5)
        await source.insert(second)
        await source.signalChange()

        // The next cutoff published is the one after the second change, so the first published nothing.
        #expect(try #require(await cutoffs.next()) == expected(Self.latte, after: [first, longAgo, second]))
    }

    // MARK: - CUTREPO-4: at each minute, a new cutoff only if it changed

    @Test func theMinuteAfterTheCutoffPassesThereIsNoCutoff() async throws {
        let drinks = [Self.drink(hours: 7)]
        let latestCup = try #require(expected(Self.latte, after: drinks).latestCup)
        let pastIt = latestCup.addingTimeInterval(60)
        let minutes = [Self.now.addingTimeInterval(60), Self.now.addingTimeInterval(120), pastIt]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks), minutes: minutes)

        var cutoffs = repository.cutoff(in: Self.utc).makeAsyncIterator()
        _ = try #require(await cutoffs.next())

        // The minutes before the cutoff leave it alone, so the next cutoff is the one once it has passed.
        let passed = try #require(await cutoffs.next())
        #expect(try passed == expected(Self.latte, after: drinks, now: pastIt))
        #expect(passed.latestCup == nil)
    }

    // MARK: - CUTREPO-5: the upcoming cutoffs, for several nights

    func expectedUpcoming(nights: Int, after drinks: [LoggedDrink], now: Date = now) -> [CaffeineCutoff] {
        let inputs = CaffeineCutoffRule.Inputs(
            drink: Self.latte, intakes: drinks.map(\.intake), kinetics: .standard, threshold: .standard,
            bedtime: .standard)
        return rule.cutoffs(inputs, nights: nights, now: now, calendar: Self.utc)
    }

    @Test func aNewSubscriberGetsTheUpcomingCutoffsForTheCurrentTime() async throws {
        let drinks = [Self.drink(hours: 8)]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks))

        var upcoming = repository.upcomingCutoffs(nights: 3, in: Self.utc).makeAsyncIterator()

        let first = try #require(await upcoming.next())
        #expect(first == expectedUpcoming(nights: 3, after: drinks))
        #expect(first.count == 3)
    }

    @Test func theUpcomingCutoffsFollowAChangeToTheDrinkLog() async throws {
        let first = Self.drink(hours: 7)
        let source = FakeDrinkLogDataSource(drinks: [first])
        let repository = Self.repository(source)
        var upcoming = repository.upcomingCutoffs(nights: 2, in: Self.utc).makeAsyncIterator()
        _ = await upcoming.next()

        let second = Self.drink(hours: 8.5)
        await source.insert(second)
        await source.signalChange()

        #expect(try #require(await upcoming.next()) == expectedUpcoming(nights: 2, after: [first, second]))
    }

    /// The minutes before tonight's cutoff change nothing, so the next value is the one once it has passed.
    @Test func theUpcomingCutoffsChangeAtAMinuteOnlyWhenACutoffPasses() async throws {
        let drinks = [Self.drink(hours: 7)]
        let latestCup = try #require(expectedUpcoming(nights: 2, after: drinks).first?.latestCup)
        let pastIt = latestCup.addingTimeInterval(60)
        let minutes = [Self.now.addingTimeInterval(60), Self.now.addingTimeInterval(120), pastIt]
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: drinks), minutes: minutes)

        var upcoming = repository.upcomingCutoffs(nights: 2, in: Self.utc).makeAsyncIterator()
        _ = try #require(await upcoming.next())

        let passed = try #require(await upcoming.next())
        #expect(passed == expectedUpcoming(nights: 2, after: drinks, now: pastIt))
        #expect(passed.first?.latestCup == nil)
    }
}
