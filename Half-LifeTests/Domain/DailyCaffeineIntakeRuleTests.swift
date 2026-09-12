//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DailyCaffeineIntakeRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the day's intake against INTAKE-1 to INTAKE-4 in the Today Screen article. The rule is pure, so its tests
/// need no fakes.
struct DailyCaffeineIntakeRuleTests {

    let rule = DailyCaffeineIntakeRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func drink(_ milligrams: Double, at date: Date) -> LoggedDrink {
        LoggedDrink(type: .espresso, quantity: 1, milligrams: milligrams, consumedAt: date)
    }

    // MARK: - INTAKE-1: the sum of the drinks consumed on the current day, from midnight to the next midnight

    @Test func sumsTheDrinksConsumedOnTheCurrentDay() {
        let drinks = [Self.drink(128, at: Self.date(8)), Self.drink(64, at: Self.date(10.75))]

        let intake = rule.intake(from: drinks, on: Self.date(16), calendar: Self.utc)

        #expect(intake == DailyCaffeineIntake(day: Self.midnight, milligrams: 192))
    }

    @Test func countsADrinkAtMidnightAndLeavesOutTheDaysEitherSide() {
        let drinks = [
            Self.drink(50, at: Self.midnight.addingTimeInterval(-1)),
            Self.drink(128, at: Self.midnight),
            Self.drink(64, at: Self.date(24).addingTimeInterval(-1)),
            Self.drink(205, at: Self.date(24)),
        ]

        let intake = rule.intake(from: drinks, on: Self.date(16), calendar: Self.utc)

        #expect(intake == DailyCaffeineIntake(day: Self.midnight, milligrams: 192))
    }

    // MARK: - INTAKE-2: a day with no drinks is 0 mg

    @Test func isZeroWhenNothingWasConsumedOnTheCurrentDay() {
        let intake = rule.intake(from: [Self.drink(128, at: Self.date(-2))], on: Self.date(16), calendar: Self.utc)

        #expect(intake == DailyCaffeineIntake(day: Self.midnight, milligrams: 0))
    }

    // MARK: - INTAKE-3: the day is the given calendar's

    /// 4:00pm UTC is 1:00am the next day in Tokyo, whose day started at 3:00pm UTC. Only the drink at 3:30pm UTC,
    /// 12:30am in Tokyo, is on Tokyo's day.
    @Test func findsTheDayInTheGivenCalendar() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let drinks = [Self.drink(128, at: Self.date(8)), Self.drink(64, at: Self.date(15.5))]

        let intake = rule.intake(from: drinks, on: Self.date(16), calendar: tokyo)

        #expect(intake == DailyCaffeineIntake(day: Self.date(15), milligrams: 64))
    }

    // MARK: - INTAKE-4: a day the clocks change on is still one calendar day

    /// New York's clocks go back at 2:00am on 2026-11-01, so 11:30pm that day is 24.5 hours after its midnight.
    @Test func aDayTheClocksGoBackOnRunsTwentyFiveHours() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let dayStart = try #require(newYork.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let lateEvening = try #require(
            newYork.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 23, minute: 30)))
        #expect(lateEvening.timeIntervalSince(dayStart) == 24.5 * 3_600)

        let intake = rule.intake(
            from: [Self.drink(95, at: lateEvening)], on: dayStart.addingTimeInterval(12 * 3_600), calendar: newYork)

        #expect(intake == DailyCaffeineIntake(day: dayStart, milligrams: 95))
    }
}
