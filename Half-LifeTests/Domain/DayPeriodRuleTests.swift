//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DayPeriodRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the day periods that greetings are chosen by (PERIOD-1 and PERIOD-2 in the Today Screen article).
struct DayPeriodRuleTests {

    private func calendar(in timeZone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        return calendar
    }

    /// PERIOD-1: each boundary minute belongs to the period it starts.
    @Test(arguments: [
        (4, 59, DayPeriod.evening),
        (5, 0, DayPeriod.morning),
        (11, 59, DayPeriod.morning),
        (12, 0, DayPeriod.afternoon),
        (16, 59, DayPeriod.afternoon),
        (17, 0, DayPeriod.evening),
        (23, 59, DayPeriod.evening),
        (0, 0, DayPeriod.evening),
    ])
    func periodAtEachBoundary(hour: Int, minute: Int, expected: DayPeriod) throws {
        let calendar = try calendar(in: "UTC")
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 11, hour: hour, minute: minute))
        )

        #expect(DayPeriodRule().period(at: date, calendar: calendar) == expected)
    }

    /// PERIOD-2: 01:00 UTC on 2026-09-11 is 10:00 in Tokyo and 21:00 the evening before in New York.
    @Test func periodFollowsTheCalendarsTimeZone() throws {
        let utc = try calendar(in: "UTC")
        let instant = try #require(utc.date(from: DateComponents(year: 2026, month: 9, day: 11, hour: 1)))
        let rule = DayPeriodRule()

        #expect(rule.period(at: instant, calendar: try calendar(in: "Asia/Tokyo")) == .morning)
        #expect(rule.period(at: instant, calendar: try calendar(in: "America/New_York")) == .evening)
    }
}
