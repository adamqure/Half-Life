//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkDeletionTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks DELETE-3 in the Today Screen article: a drink deleted through the drink log repository reaches the caffeine
/// decay repository through the data source they share, as the app wires them. The time limit turns a value that
/// never arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct DrinkDeletionTests {

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    /// 8:00pm on the worked examples' day.
    static let evening = midnight.addingTimeInterval(20 * 3_600)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    static func drink(_ milligrams: Double, hours: Double) -> LoggedDrink {
        let consumedAt = midnight.addingTimeInterval(hours * 3_600)
        return LoggedDrink(type: .espresso, quantity: 1, milligrams: milligrams, consumedAt: consumedAt)
    }

    /// The worked examples' day of drinks: 128 mg at 8:00am, 64 mg at 10:45am, and 205 mg at 3:00pm.
    static let dayOfDrinks = [drink(128, hours: 8), drink(64, hours: 10.75), drink(205, hours: 15)]

    /// DELETE-3: deleting the 3:00pm cup recalculates the curve, the status, and today's intake without it.
    @Test func deletingADrinkRecalculatesTheCurveTheStatusAndTodaysIntake() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks)
        let clock = FakeClockDataSource(date: Self.evening, minuteDates: [])
        let drinkLog = LiveDrinkLogRepository(dataSource: source, clock: clock)
        let decay = LiveCaffeineDecayRepository(
            drinkLog: source, halfLife: FakeHalfLifeDataSource(value: .standard),
            absorption: FakeAbsorptionRateDataSource(value: .standard),
            bedtime: FakeBedtimeDataSource(value: .standard), clock: clock)
        var curves = decay.curve().makeAsyncIterator()
        var statuses = decay.status(in: Self.utc).makeAsyncIterator()
        var intakes = drinkLog.intakeToday(in: Self.utc).makeAsyncIterator()
        _ = await curves.next()
        _ = await statuses.next()
        _ = await intakes.next()

        try await drinkLog.delete(Self.dayOfDrinks[2].id)

        let remaining = Self.dayOfDrinks.prefix(2).map(\.intake)
        #expect(
            try #require(await curves.next())
                == CaffeineDecayRule().curve(from: remaining, kinetics: .standard, now: Self.evening))
        #expect(
            try #require(await statuses.next())
                == CaffeineStatusRule().status(
                    from: remaining, kinetics: .standard, bedtime: .standard, now: Self.evening, calendar: Self.utc))
        #expect(try #require(await intakes.next()) == DailyCaffeineIntake(day: Self.midnight, milligrams: 192))
    }
}
