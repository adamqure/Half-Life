//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepNeedRuleTests
//

import Foundation
import Testing

@testable import Half_Life

struct SleepNeedRuleTests {

    let rule = SleepNeedRule()

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midsummer 2026, in UTC.
    static let now: Date = {
        let components = DateComponents(year: 2026, month: 6, day: 15, hour: 12)
        return utc.date(from: components) ?? .distantPast
    }()

    func sleep(bornIn birthYear: Int?, now: Date = now, calendar: Calendar = utc) -> RecommendedSleep {
        rule.recommendedSleep(birthYear: birthYear, now: now, calendar: calendar)
    }

    // MARK: - SLEEPNEED-1: each age range gets its recommended sleep

    @Test func teenagersNeedEightToTenHours() {
        #expect(sleep(bornIn: 2013) == .teen)
        #expect(sleep(bornIn: 2009) == .teen)
        #expect(RecommendedSleep.teen == RecommendedSleep(minimumHours: 8, maximumHours: 10))
    }

    @Test func adultsNeedSevenToNineHours() {
        #expect(sleep(bornIn: 2008) == .adult)
        #expect(sleep(bornIn: 1962) == .adult)
        #expect(RecommendedSleep.adult == RecommendedSleep(minimumHours: 7, maximumHours: 9))
    }

    @Test func olderAdultsNeedSevenToEightHours() {
        #expect(sleep(bornIn: 1961) == .olderAdult)
        #expect(sleep(bornIn: 1930) == .olderAdult)
        #expect(RecommendedSleep.olderAdult == RecommendedSleep(minimumHours: 7, maximumHours: 8))
    }

    @Test func aRangeIsInSeconds() {
        #expect(RecommendedSleep.adult.minimumSeconds == 25_200)
        #expect(RecommendedSleep.adult.maximumSeconds == 32_400)
    }

    // MARK: - SLEEPNEED-2: with no birth year, it's the adult range

    @Test func withNoBirthYearItsTheAdultRange() {
        #expect(sleep(bornIn: nil) == .adult)
    }

    // MARK: - SLEEPNEED-3: the age is the current year, in the given calendar, minus the birth year

    @Test func theAgeFollowsTheCalendarsYear() throws {
        // 2:00am UTC on New Year's Day 2026 is still 2025 in New York.
        let newYear = try #require(Self.utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 2)))
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try #require(TimeZone(identifier: "America/New_York"))

        #expect(sleep(bornIn: 2008, now: newYear, calendar: Self.utc) == .adult)
        #expect(sleep(bornIn: 2008, now: newYear, calendar: newYork) == .teen)
    }
}
