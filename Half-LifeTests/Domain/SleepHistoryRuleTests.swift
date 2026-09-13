//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepHistoryRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the sleep history against SLEEPHIST-1 to SLEEPHIST-4 in the Insights article. The rule is pure, so its tests
/// need no fakes. Each night is checked against ``LastNightSleepRule``, so the Insights card and the Today screen's
/// Apple Health card always agree on a night.
struct SleepHistoryRuleTests {

    let rule = SleepHistoryRule()
    let lastNightRule = LastNightSleepRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 4:00pm today.
    static let now = date(16)

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    /// Three days ago's night in bed without sleep, 10:30pm to 6:30am. Two days ago's night, 11pm to 6am, 7 hours.
    /// Last night, 11pm to 6:30am, 7.5 hours. And a morning today, 9:00am to 12:30pm, that ends after noon.
    static let intervals = [
        SleepStageInterval(stage: .inBed, start: date(-72 + 22.5), end: date(-48 + 6.5)),
        SleepStageInterval(stage: .core, start: date(-48 + 23), end: date(-24 + 6)),
        SleepStageInterval(stage: .core, start: date(-1), end: date(6.5)),
        SleepStageInterval(stage: .core, start: date(9), end: date(12.5)),
    ]

    // MARK: - SLEEPHIST-1: one night per day, oldest first, each the night after it from noon to noon

    @Test func eachDaysNightIsTheOneEndingFromNoonThatDayToNoonTheNext() {
        let nights = rule.nights(from: Self.intervals, endingAt: Self.now, days: 4, calendar: Self.utc)

        #expect(nights.map(\.day) == [Self.date(-72), Self.date(-48), Self.date(-24), Self.midnight])
        #expect(nights[0].sleep == .inBedOnly(seconds: 8 * 3_600))
        #expect(nights[1].sleep == .asleep(seconds: 7 * 3_600))
        #expect(nights[2].sleep == .asleep(seconds: 7.5 * 3_600))
        for (index, night) in nights.dropLast().enumerated() {
            let noonNextDay = Self.date(Double(index - 3) * 24 + 36)
            #expect(night.sleep == lastNightRule.lastNight(from: Self.intervals, at: noonNextDay, calendar: Self.utc))
        }
    }

    // MARK: - SLEEPHIST-2: today's night hasn't happened, so it's empty

    @Test func todaysNightIsAlwaysEmpty() {
        let nights = rule.nights(from: Self.intervals, endingAt: Self.now, days: 4, calendar: Self.utc)

        #expect(nights.last?.sleep == nil)
    }

    // MARK: - SLEEPHIST-3: a day with no sleep and no time in bed has an empty night

    @Test func aDayWithNothingRecordedHasAnEmptyNight() {
        let nights = rule.nights(from: Self.intervals, endingAt: Self.now, days: 5, calendar: Self.utc)

        #expect(nights.first?.day == Self.date(-96))
        #expect(nights.first?.sleep == nil)
    }

    // MARK: - SLEEPHIST-4: sleep is read once, from noon the day before the first night to noon today

    /// The read ends at noon today, where last night's window ends, as the Today screen's Apple Health card reads it,
    /// so a night that hasn't finished gives both cards the same answer. It's noon today in the afternoon and at 1am.
    @Test func sleepIsReadFromNoonTheDayBeforeTheFirstNightToNoonToday() {
        #expect(
            rule.range(endingAt: Self.now, days: 4, calendar: Self.utc)
                == DateInterval(start: Self.date(-84), end: Self.date(12)))
        #expect(rule.range(endingAt: Self.date(1), days: 4, calendar: Self.utc)?.end == Self.date(12))
    }

    /// The days follow the calendar's time zone: 4:00pm UTC is 1:00am the next day in Tokyo.
    @Test func theDaysFollowTheCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let nights = rule.nights(from: [], endingAt: Self.now, days: 2, calendar: tokyo)

        #expect(nights.map(\.day) == [Self.date(-9), Self.date(15)])
    }
}
