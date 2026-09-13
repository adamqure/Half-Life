//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepNightRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the rule that turns Health's sleep intervals into nights (NIGHT-1 to NIGHT-6 in the Half-Life Estimator
/// article).
struct SleepNightRuleTests {

    let rule = SleepNightRule()

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midnight at the start of 1 June 2026, in UTC.
    static let midnight = utc.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? .distantPast

    /// The moment `hours` after ``midnight``.
    static func at(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    /// An interval in `stage` from `start` to `end`, in hours after ``midnight``.
    static func interval(_ stage: SleepStageInterval.Stage, _ start: Double, _ end: Double) -> SleepStageInterval {
        SleepStageInterval(stage: stage, start: at(start), end: at(end))
    }

    /// A night from 11pm to 6:30am, recorded with stages.
    static let stagedNight = [
        interval(.core, 23, 24.5), interval(.deep, 24.5, 25.5), interval(.awake, 25.5, 25.75),
        interval(.rem, 25.75, 27), interval(.core, 27, 30.5),
    ]

    // MARK: - NIGHT-1: a night recorded with stages

    @Test func aStagedNightRunsFromTheFirstSleepToTheLastAndTotalsItsDeepSleepAndTimeAwake() {
        let intervals = [Self.interval(.inBed, 22.5, 31)] + Self.stagedNight

        #expect(
            rule.nights(from: intervals) == [
                SleepNight(sleepOnset: Self.at(23), wake: Self.at(30.5), deepSeconds: 3_600, awakeSeconds: 900)
            ])
    }

    // MARK: - NIGHT-2: overlapping trackers count once

    @Test func overlappingTrackersAreMergedAndCountedOnce() {
        let intervals = [
            Self.interval(.asleepUnspecified, 22.75, 30.75),
            Self.interval(.core, 23, 27), Self.interval(.deep, 24, 25), Self.interval(.deep, 24, 25),
            Self.interval(.deep, 24.5, 25.25), Self.interval(.rem, 27, 30),
        ]

        #expect(
            rule.nights(from: intervals) == [
                SleepNight(sleepOnset: Self.at(22.75), wake: Self.at(30.75), deepSeconds: 4_500, awakeSeconds: 0)
            ])
    }

    // MARK: - NIGHT-3: a gap of more than an hour ends a session, and a session under 3 hours asleep isn't a night

    @Test func aNapIsNotANight() {
        let nap = [Self.interval(.core, 38, 39), Self.interval(.deep, 39, 39.5)]

        #expect(rule.nights(from: Self.stagedNight + nap).count == 1)
    }

    @Test func aGapOfMoreThanAnHourSplitsTheSleepIntoSessions() {
        let intervals = [
            Self.interval(.core, 23, 24), Self.interval(.deep, 24, 25), Self.interval(.core, 26.01, 28),
        ]

        #expect(rule.nights(from: intervals).isEmpty)
    }

    @Test func aGapOfExactlyAnHourStaysInTheSession() {
        let intervals = [
            Self.interval(.core, 23, 24), Self.interval(.deep, 24, 25), Self.interval(.core, 26, 28),
        ]

        #expect(
            rule.nights(from: intervals) == [
                SleepNight(sleepOnset: Self.at(23), wake: Self.at(28), deepSeconds: 3_600, awakeSeconds: 0)
            ])
    }

    @Test func aLongAwakeningDoesntSplitTheNight() {
        let intervals = [
            Self.interval(.core, 23, 25), Self.interval(.deep, 25, 26), Self.interval(.awake, 26, 27.5),
            Self.interval(.core, 27.5, 30),
        ]

        #expect(
            rule.nights(from: intervals) == [
                SleepNight(sleepOnset: Self.at(23), wake: Self.at(30), deepSeconds: 3_600, awakeSeconds: 5_400)
            ])
    }

    @Test func exactlyThreeHoursAsleepIsANight() {
        #expect(rule.nights(from: [Self.interval(.core, 23, 26)]).count == 1)
        #expect(rule.nights(from: [Self.interval(.core, 23, 25.99)]).isEmpty)
    }

    // MARK: - NIGHT-4: sleep without stages isn't a night

    @Test func sleepRecordedWithoutStagesIsNotANight() {
        #expect(rule.nights(from: [Self.interval(.asleepUnspecified, 23, 30.5)]).isEmpty)
    }

    // MARK: - NIGHT-5: time in bed and time awake outside the session don't count

    @Test func timeAwakeBeforeFallingAsleepAndAfterWakingDoesntCount() {
        let intervals =
            [Self.interval(.inBed, 21, 32), Self.interval(.awake, 22, 23)] + Self.stagedNight
            + [Self.interval(.awake, 30.5, 31)]

        #expect(
            rule.nights(from: intervals) == [
                SleepNight(sleepOnset: Self.at(23), wake: Self.at(30.5), deepSeconds: 3_600, awakeSeconds: 900)
            ])
    }

    // MARK: - NIGHT-6: nights come back in order of onset

    @Test func nightsComeBackInOrderOfOnset() {
        let secondNight = [Self.interval(.core, 47, 50), Self.interval(.deep, 50, 51)]

        let nights = rule.nights(from: (secondNight + Self.stagedNight).reversed())

        #expect(nights.map(\.sleepOnset) == [Self.at(23), Self.at(47)])
    }

    @Test func noIntervalsGiveNoNights() {
        #expect(rule.nights(from: []).isEmpty)
    }
}
