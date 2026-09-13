//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogRecentDaysRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the last several days of the drink log against RECENTRULE-1 to RECENTRULE-3 in the Insights article. The rule
/// is pure, so its tests need no fakes. Each day is checked against the rule's own single day, so the Insights card and
/// the history card always agree.
struct DrinkLogRecentDaysRuleTests {

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

    /// A cup eight days ago, one two days ago at 9:00pm, two today, and one tomorrow.
    static let drinks = [
        drink(95, hours: -8 * 24 + 9), drink(64, hours: -2 * 24 + 21), drink(128, hours: 8), drink(64, hours: 10.75),
        drink(205, hours: 33),
    ]

    // MARK: - RECENTRULE-1: the days end with the one that holds the date, oldest first

    @Test func theDaysEndWithTheDayThatHoldsTheDateOldestFirst() {
        let days = rule.days(endingOn: Self.date(16), count: 7, from: Self.drinks, calendar: Self.utc)

        #expect(days.map(\.intake.day) == (-6...0).map { Self.date(Double($0) * 24) })
    }

    // MARK: - RECENTRULE-2: each day is the rule's own day, so a day with no drinks is empty

    @Test func eachDayIsTheSameAsTheRulesOwnDay() {
        let days = rule.days(endingOn: Self.date(16), count: 7, from: Self.drinks, calendar: Self.utc)

        #expect(
            days
                == (-6...0).map {
                    rule.day(containing: Self.date(Double($0) * 24 + 12), from: Self.drinks, calendar: Self.utc)
                })
        #expect(days[4].drinks == [Self.drinks[1]])
        #expect(days[5].intake.milligrams == 0)
        #expect(days[6].intake.milligrams == 192)
    }

    // MARK: - RECENTRULE-3: the days follow the calendar's time zone

    /// 4:00pm UTC is 1:00am the next day in Tokyo, so Tokyo's last day starts at 3:00pm UTC.
    @Test func theDaysFollowTheCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let days = rule.days(endingOn: Self.date(16), count: 2, from: Self.drinks, calendar: tokyo)

        #expect(days.map(\.intake.day) == [Self.date(-9), Self.date(15)])
    }
}
