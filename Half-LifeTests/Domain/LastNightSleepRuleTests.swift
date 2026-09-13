//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LastNightSleepRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the rule that finds last night for the Apple Health card, against LASTNIGHT-1 to LASTNIGHT-7 in the Apple
/// Health Card article.
///
/// The rule is pure, so its tests need no fakes. Times are in New York's time zone, around March 10, 2026, when the
/// clocks don't change, except in LASTNIGHT-7.
struct LastNightSleepRuleTests {
    let calendar: Calendar
    /// Midnight at the start of March 10, 2026, in New York.
    let march10: Date
    let rule = LastNightSleepRule()

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        self.calendar = calendar
        march10 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)))
    }

    /// `hours` after midnight on March 10, so 31 is 7am on March 11.
    func at(_ hours: Double) -> Date {
        march10.addingTimeInterval(hours * 3_600)
    }

    func stretch(_ stage: SleepStageInterval.Stage, from start: Double, to end: Double) -> SleepStageInterval {
        SleepStageInterval(stage: stage, start: at(start), end: at(end))
    }

    // MARK: - LASTNIGHT-1: the latest session ending from noon yesterday to noon today, all day

    @Test func lastNightIsTheLatestSessionEndingBetweenNoonYesterdayAndNoonToday() {
        let intervals = [
            stretch(.core, from: -1, to: 7),  // Ends at 7am on March 10.
            stretch(.core, from: 23, to: 30),  // Ends at 6am on March 11.
        ]

        #expect(rule.lastNight(from: intervals, at: at(31.5), calendar: calendar) == .asleep(seconds: 7 * 3_600))
        #expect(rule.lastNight(from: intervals, at: at(45), calendar: calendar) == .asleep(seconds: 7 * 3_600))
        #expect(rule.lastNight(from: intervals, at: at(21), calendar: calendar) == .asleep(seconds: 8 * 3_600))
    }

    @Test func theNightRunsFromNoonYesterdayToNoonToday() throws {
        let night = try #require(rule.night(containing: at(31), calendar: calendar))

        #expect(night == DateInterval(start: at(12), end: at(36)))
    }

    @Test func noonYesterdayIsIncludedAndNoonTodayIsNot() {
        let endsAtNoonYesterday = [stretch(.core, from: 4, to: 12)]
        let endsAtNoonToday = [stretch(.core, from: 28, to: 36)]

        #expect(
            rule.lastNight(from: endsAtNoonYesterday, at: at(33), calendar: calendar) == .asleep(seconds: 8 * 3_600))
        #expect(rule.lastNight(from: endsAtNoonToday, at: at(33), calendar: calendar) == nil)
    }

    // MARK: - LASTNIGHT-2: time asleep counts overlapping trackers once, and leaves out time awake and in bed

    @Test func timeAsleepCountsOverlapsOnceAndLeavesOutTimeAwakeAndInBed() {
        let intervals = [
            stretch(.inBed, from: 22.5, to: 31.25),
            stretch(.core, from: 23, to: 27),
            stretch(.awake, from: 27, to: 27.5),
            stretch(.deep, from: 27.5, to: 31),
            stretch(.asleepUnspecified, from: 23.5, to: 26),
        ]

        #expect(rule.lastNight(from: intervals, at: at(32), calendar: calendar) == .asleep(seconds: 7.5 * 3_600))
    }

    // MARK: - LASTNIGHT-3: sleep recorded without stages counts

    @Test func sleepRecordedWithoutStagesCounts() {
        let intervals = [stretch(.asleepUnspecified, from: 23, to: 30)]

        #expect(rule.lastNight(from: intervals, at: at(32), calendar: calendar) == .asleep(seconds: 7 * 3_600))
        #expect(SleepNightRule().nights(from: intervals).isEmpty)
    }

    // MARK: - LASTNIGHT-4: a session with less than 3 hours of sleep is a nap

    @Test func aNapIsNotLastNight() {
        let nap = [stretch(.core, from: 14, to: 16)]

        #expect(rule.lastNight(from: nap, at: at(33), calendar: calendar) == nil)
    }

    @Test func aMorningNapDoesNotReplaceTheNightBeforeIt() {
        let intervals = [
            stretch(.core, from: 23, to: 30),
            stretch(.core, from: 33, to: 34.5),  // 9am to 10:30am, after more than an hour awake.
        ]

        #expect(rule.lastNight(from: intervals, at: at(35), calendar: calendar) == .asleep(seconds: 7 * 3_600))
    }

    // MARK: - LASTNIGHT-5: time in bed is the fallback when no sleep was recorded

    @Test func timeInBedAloneIsInBedOnly() {
        let intervals = [stretch(.inBed, from: 22, to: 31)]

        #expect(rule.lastNight(from: intervals, at: at(32), calendar: calendar) == .inBedOnly(seconds: 9 * 3_600))
    }

    @Test func sleepIsShownWhenThereIsTimeInBedToo() {
        let intervals = [stretch(.inBed, from: 22, to: 31), stretch(.core, from: 23, to: 30)]

        #expect(rule.lastNight(from: intervals, at: at(32), calendar: calendar) == .asleep(seconds: 7 * 3_600))
    }

    @Test func lessThanThreeHoursInBedIsNothing() {
        let intervals = [stretch(.inBed, from: 22, to: 24.5)]

        #expect(rule.lastNight(from: intervals, at: at(32), calendar: calendar) == nil)
    }

    // MARK: - LASTNIGHT-6: no sleep and no time in bed in the window give nothing

    @Test func noIntervalsGiveNoLastNight() {
        #expect(rule.lastNight(from: [], at: at(32), calendar: calendar) == nil)
    }

    @Test func sleepEndingBeforeTheWindowGivesNoLastNight() {
        let intervals = [stretch(.core, from: -1, to: 7), stretch(.inBed, from: -2, to: 8)]

        #expect(rule.lastNight(from: intervals, at: at(32), calendar: calendar) == nil)
    }

    // MARK: - LASTNIGHT-7: a window the clocks change in is still noon to noon

    @Test func aWindowTheClocksChangeInIsStillNoonToNoon() throws {
        // New York's clocks went forward at 2am on March 8, 2026.
        let noonMarch7 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 12)))
        let noonMarch8 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))
        let now = noonMarch8.addingTimeInterval(-3 * 3_600)

        let night = try #require(rule.night(containing: now, calendar: calendar))
        let endsJustBeforeTheWindow = [
            SleepStageInterval(
                stage: .core, start: noonMarch7.addingTimeInterval(-8 * 3_600), end: noonMarch7.addingTimeInterval(-60))
        ]

        #expect(night == DateInterval(start: noonMarch7, end: noonMarch8))
        #expect(night.duration == 23 * 3_600)
        #expect(rule.lastNight(from: endsJustBeforeTheWindow, at: now, calendar: calendar) == nil)
    }
}
