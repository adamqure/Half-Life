//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogDayRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the drink log history's rule against HISTRULE-1 to HISTRULE-4 in the Today Screen article. The rule is
/// pure, so its tests need no fakes.
struct DrinkLogDayRuleTests {

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

    /// A cup at 10:00pm yesterday, 128 mg at 8:00am and 64 mg at 10:45am today, and 205 mg at 9:00am tomorrow.
    static let yesterday = drink(95, hours: -2)
    static let morning = drink(128, hours: 8)
    static let lateMorning = drink(64, hours: 10.75)
    static let tomorrow = drink(205, hours: 33)
    static let drinks = [yesterday, morning, lateMorning, tomorrow]

    // MARK: - HISTRULE-1: the drinks consumed on the day, in the order given

    @Test func holdsOnlyTheDrinksConsumedOnTheDayInTheOrderGiven() {
        let day = rule.day(containing: Self.date(16), from: Self.drinks, calendar: Self.utc)

        #expect(day.drinks == [Self.morning, Self.lateMorning])
    }

    @Test func anyMomentInTheDayGivesTheSameDay() {
        let early = rule.day(containing: Self.date(0.5), from: Self.drinks, calendar: Self.utc)
        let late = rule.day(containing: Self.date(23.9), from: Self.drinks, calendar: Self.utc)

        #expect(early == late)
    }

    @Test func aDayWithNoDrinksIsEmpty() {
        let day = rule.day(containing: Self.date(-48), from: Self.drinks, calendar: Self.utc)

        #expect(day.drinks.isEmpty)
        #expect(day.intake == DailyCaffeineIntake(day: Self.date(-48), milligrams: 0))
    }

    // MARK: - HISTRULE-2: midnight is included, and the next midnight isn't

    @Test func midnightStartsTheDayAndTheNextMidnightStartsTheNext() {
        let atMidnight = Self.drink(50, hours: 0)
        let atNextMidnight = Self.drink(70, hours: 24)

        let day = rule.day(containing: Self.date(12), from: [atMidnight, atNextMidnight], calendar: Self.utc)

        #expect(day.drinks == [atMidnight])
    }

    // MARK: - HISTRULE-3: the day's intake is DailyCaffeineIntakeRule's

    @Test func theIntakeIsTheDailyIntakeRulesForTheSameDay() {
        let day = rule.day(containing: Self.date(16), from: Self.drinks, calendar: Self.utc)

        #expect(day.intake == DailyCaffeineIntake(day: Self.midnight, milligrams: 192))
        #expect(
            day.intake == DailyCaffeineIntakeRule().intake(from: Self.drinks, on: Self.date(16), calendar: Self.utc))
    }

    // MARK: - HISTRULE-4: the day follows the calendar's time zone

    /// At 4:00pm UTC it's 1:00am in Tokyo, on a day that started at 3:00pm UTC. Of the drinks, only tomorrow's 9:00am
    /// UTC cup falls on it.
    @Test func findsTheDayInTheGivenCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let day = rule.day(containing: Self.date(16), from: Self.drinks, calendar: tokyo)

        #expect(day.drinks == [Self.tomorrow])
        #expect(day.intake == DailyCaffeineIntake(day: Self.date(15), milligrams: 205))
    }
}
