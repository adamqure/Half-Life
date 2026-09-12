//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineStatusRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the rule behind the decay card's figure and tips (STATUS-1 to STATUS-6 in the Today Screen article).
///
/// The drinks are the Caffeine Decay Model article's "day of drinks": 128 mg at 8:00am, 64 mg at 10:45am, and 205 mg
/// at 3:00pm, with the standard 5.5-hour half-life and 13-minute absorption half-life, on 2026-09-11 in UTC.
struct CaffeineStatusRuleTests {

    private let rule = CaffeineStatusRule()
    private let kinetics = CaffeineKinetics.standard

    private func utc() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        return calendar
    }

    private func date(day: Int = 11, _ hour: Int, _ minute: Int = 0, in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute)))
    }

    private func dayOfDrinks(in calendar: Calendar) throws -> [CaffeineIntake] {
        [
            CaffeineIntake(id: UUID(), milligrams: 128, consumedAt: try date(8, in: calendar)),
            CaffeineIntake(id: UUID(), milligrams: 64, consumedAt: try date(10, 45, in: calendar)),
            CaffeineIntake(id: UUID(), milligrams: 205, consumedAt: try date(15, in: calendar)),
        ]
    }

    private func rounded(_ milligrams: Double) -> Double {
        (milligrams * 100).rounded() / 100
    }

    /// The status at `now`, with the standard half-life and absorption rate.
    private func status(
        from intakes: [CaffeineIntake], bedtime: Bedtime = .standard, now: Date, calendar: Calendar
    ) -> CaffeineStatus {
        rule.status(from: intakes, kinetics: kinetics, bedtime: bedtime, now: now, calendar: calendar)
    }

    /// STATUS-1: the level is the decay rule's level at the current time. At 4:00pm that's 262.43 mg.
    @Test func levelIsTheDecayRulesLevelNow() throws {
        let calendar = try utc()
        let now = try date(16, in: calendar)

        let status = status(from: try dayOfDrinks(in: calendar), now: now, calendar: calendar)

        #expect(status.level.date == now)
        #expect(rounded(status.level.milligrams) == 262.43)
    }

    /// STATUS-2: the drinks still in your system are the intakes that count now, in the order given. An intake
    /// consumed later, or one that's negligible now, isn't among them.
    @Test func activeIntakesAreTheOnesThatCountNow() throws {
        let calendar = try utc()
        let now = try date(12, in: calendar)
        let counting = CaffeineIntake(id: UUID(), milligrams: 128, consumedAt: try date(8, in: calendar))
        let later = CaffeineIntake(id: UUID(), milligrams: 205, consumedAt: try date(15, in: calendar))
        let negligible = CaffeineIntake(id: UUID(), milligrams: 1, consumedAt: try date(day: 9, 12, in: calendar))

        let status = status(from: [negligible, counting, later], now: now, calendar: calendar)

        #expect(status.activeIntakes == [counting])
    }

    /// STATUS-2: a drink consumed this minute adds 0 mg, because none of it has reached the body yet, but it's in
    /// your system.
    @Test func drinkConsumedNowIsActiveAtZeroMilligrams() throws {
        let calendar = try utc()
        let now = try date(15, in: calendar)
        let justNow = CaffeineIntake(id: UUID(), milligrams: 205, consumedAt: now)

        let status = status(from: [justNow], now: now, calendar: calendar)

        #expect(status.activeIntakes == [justNow])
        #expect(status.level.milligrams == 0)
    }

    /// STATUS-3: the last cup is half gone once its own level falls to half its dose, after its peak. For the 3:00pm
    /// cup, that's 20,948.07 seconds later, at about 8:49:08pm: 19 minutes later than one half-life.
    @Test func lastIntakeIsHalfGoneWhenItsLevelFallsToHalfItsDose() throws {
        let calendar = try utc()

        let status = status(from: try dayOfDrinks(in: calendar), now: try date(16, in: calendar), calendar: calendar)

        let halfGone = try #require(status.lastIntakeHalfGoneAt)
        #expect(abs(halfGone.timeIntervalSince(try date(15, in: calendar)) - 20_948.07) < 0.01)
    }

    /// STATUS-3: once that moment has passed, or when nothing is counting, there's no half-gone time.
    @Test func noHalfGoneTimeOnceItHasPassedOrWhenNothingCounts() throws {
        let calendar = try utc()

        let passed = status(from: try dayOfDrinks(in: calendar), now: try date(21, in: calendar), calendar: calendar)
        let empty = status(from: [], now: try date(21, in: calendar), calendar: calendar)

        #expect(passed.lastIntakeHalfGoneAt == nil)
        #expect(empty.lastIntakeHalfGoneAt == nil)
    }

    /// STATUS-4: the level at bedtime is the decay rule's level at the next bedtime. With an 11:00pm bedtime, at
    /// 3:00pm, that's 112.22 mg at 11:00pm tonight.
    @Test func levelAtBedtimeIsTheLevelAtTonightsBedtime() throws {
        let calendar = try utc()
        let bedtime = try #require(Bedtime(hour: 23, minute: 0))

        let status = status(
            from: try dayOfDrinks(in: calendar), bedtime: bedtime, now: try date(15, in: calendar), calendar: calendar)

        let atBedtime = try #require(status.levelAtBedtime)
        #expect(atBedtime.date == (try date(23, in: calendar)))
        #expect(rounded(atBedtime.milligrams) == 112.22)
    }

    /// STATUS-5: the next bedtime is the first one at or after now. Exactly at bedtime it's tonight's, and after
    /// bedtime it's tomorrow's.
    @Test func nextBedtimeIsTheFirstAtOrAfterNow() throws {
        let calendar = try utc()
        let bedtime = try #require(Bedtime(hour: 23, minute: 0))
        let intakes = try dayOfDrinks(in: calendar)

        let atBedtime = status(from: intakes, bedtime: bedtime, now: try date(23, in: calendar), calendar: calendar)
        let afterBedtime = status(
            from: intakes, bedtime: bedtime, now: try date(23, 30, in: calendar), calendar: calendar)

        #expect(atBedtime.levelAtBedtime?.date == (try date(23, in: calendar)))
        let tomorrow = try date(day: 12, 23, in: calendar)
        #expect(afterBedtime.levelAtBedtime?.date == tomorrow)
        let expected = CaffeineDecayRule().level(at: tomorrow, from: intakes, kinetics: kinetics)
        #expect(afterBedtime.levelAtBedtime == expected)
    }

    /// STATUS-6: the bedtime is a time of day in the given calendar's time zone. At 20:00 UTC on the 11th, it's
    /// already 5:00am on the 12th in Tokyo, so the next 10:30pm there is 13:30 UTC on the 12th. In UTC, it would be
    /// 22:30 on the 11th.
    @Test func bedtimeFollowsTheCalendarsTimeZone() throws {
        let utc = try utc()
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let status = status(from: [], now: try date(20, in: utc), calendar: tokyo)

        #expect(status.levelAtBedtime?.date == (try date(day: 12, 13, 30, in: utc)))
        #expect(status.levelAtBedtime?.milligrams == 0)
    }
}
