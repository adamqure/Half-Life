//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineNightRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks each night's caffeine against CNIGHT-1 to CNIGHT-6 in the Insights article: at the sleep onset Health
/// recorded, or at the bedtime for a night with none. The rule is pure, so its tests need no fakes. They check it
/// against ``CaffeineDecayRule``'s levels, so the tab and the curve agree.
struct CaffeineNightRuleTests {

    let rule = CaffeineNightRule()
    let decay = CaffeineDecayRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 9am on the fourth day, so the three nights before it follow days 1 to 3.
    static let now = date(3 * 24 + 9)

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func intake(_ milligrams: Double, hours: Double) -> CaffeineIntake {
        CaffeineIntake(id: UUID(), milligrams: milligrams, consumedAt: date(hours))
    }

    func history(
        onsets: [Date] = [], intakes: [CaffeineIntake] = [], days: Int = 3, now: Date = now,
        bedtime: Bedtime = .standard, threshold: SleepThreshold = .standard, isDemo: Bool = false,
        calendar: Calendar = utc
    ) -> CaffeineNightHistory {
        let inputs = CaffeineNightRule.Inputs(
            onsets: onsets, intakes: intakes, kinetics: .standard, bedtime: bedtime, threshold: threshold,
            isDemo: isDemo)
        return rule.history(inputs, days: days, now: now, calendar: calendar)
    }

    // MARK: - CNIGHT-1: one night per day before today, oldest first, the night after yesterday last

    @Test func givesOneNightPerDayBeforeTodayOldestFirst() {
        #expect(history().nights.map(\.day) == [Self.date(0), Self.date(24), Self.date(48)])
    }

    @Test func noDaysGivesAnEmptyHistory() {
        #expect(history(days: 0).nights.isEmpty)
    }

    // MARK: - CNIGHT-2: a night with a recorded onset from noon that day to noon the next is measured at it

    /// An onset after midnight belongs to the day before it. An onset at noon starts its day's window.
    @Test func aRecordedOnsetFromNoonToNoonIsTheNightsMoment() {
        let onsets = [Self.date(23), Self.date(24 + 12), Self.date(72 + 1.5)]

        let nights = history(onsets: onsets).nights

        #expect(nights.map(\.moment) == onsets)
        #expect(nights.map(\.measuredAt) == [.sleepOnset, .sleepOnset, .sleepOnset])
    }

    /// An onset before noon belongs to the day before, which here is before the history.
    @Test func anOnsetBeforeNoonBelongsToTheDayBefore() {
        let nights = history(onsets: [Self.date(11.9)]).nights

        #expect(nights[0].measuredAt == .bedtime)
    }

    /// With two recorded onsets in one day's window, such as a night split by a long awakening, the first counts.
    @Test func theFirstOnsetInADaysWindowCounts() {
        let nights = history(onsets: [Self.date(24 + 23.5), Self.date(24 + 22)]).nights

        #expect(nights[1].moment == Self.date(24 + 22))
    }

    // MARK: - CNIGHT-3: a night with no recorded onset is measured at the bedtime

    @Test func aNightWithNoRecordedOnsetIsMeasuredAtItsBedtime() {
        let nights = history(onsets: [Self.date(24 + 23)]).nights

        #expect(nights.map(\.moment) == [Self.date(22.5), Self.date(24 + 23), Self.date(48 + 22.5)])
        #expect(nights.map(\.measuredAt) == [.bedtime, .sleepOnset, .bedtime])
    }

    /// A bedtime of 12:30am comes round after 6pm on the day before, so it belongs to that day's night.
    @Test func aBedtimeAfterMidnightBelongsToTheNightBefore() throws {
        let bedtime = try #require(Bedtime(hour: 0, minute: 30))

        #expect(
            history(bedtime: bedtime).nights.map(\.moment) == [
                Self.date(24.5), Self.date(48.5), Self.date(72.5),
            ])
    }

    // MARK: - CNIGHT-4: each night's caffeine is the decay rule's level at its moment, from every intake

    @Test func eachNightsCaffeineIsTheLevelAtItsMoment() {
        let intakes = [
            Self.intake(200, hours: 16), Self.intake(125.4, hours: 24 + 8),
            Self.intake(95, hours: 48 + 15),
        ]

        let nights = history(onsets: [Self.date(24 + 23.5)], intakes: intakes).nights

        for night in nights {
            #expect(
                night.milligrams
                    == decay.level(at: night.moment, from: intakes, kinetics: .standard).milligrams)
        }
        #expect(nights[0].milligrams > 40)
        #expect(nights[1].milligrams < 40)
    }

    /// A cup drunk after a night's moment adds nothing to that night.
    @Test func aCupAfterTheMomentAddsNothingToThatNight() {
        let nights = history(intakes: [Self.intake(200, hours: 23)]).nights

        #expect(nights[0].milligrams == 0)
        #expect(nights[1].milligrams > 0)
    }

    // MARK: - CNIGHT-7: a night is a caffeine night only when its caffeine is over the threshold

    /// At exactly the threshold, a night isn't a caffeine night. Just under it, with a threshold a milligram lower, it
    /// is.
    @Test func aCaffeineNightIsStrictlyOverTheThreshold() throws {
        let intakes = [Self.intake(200, hours: 16)]
        let level = decay.level(at: Self.date(22.5), from: intakes, kinetics: .standard).milligrams
        let atLevel = try #require(SleepThreshold(milligrams: level))
        let belowLevel = try #require(SleepThreshold(milligrams: level - 1))

        #expect(history(intakes: intakes, threshold: atLevel).nights[0].isCaffeineNight == false)
        #expect(history(intakes: intakes, threshold: belowLevel).nights[0].isCaffeineNight)
        #expect(history(intakes: intakes, threshold: belowLevel).nights[2].isCaffeineNight == false)
    }

    // MARK: - CNIGHT-5: the threshold, and whether the sleep is the demo's, are carried

    @Test func carriesTheThresholdAndWhetherTheSleepIsTheDemos() throws {
        let threshold = try #require(SleepThreshold(milligrams: 25))

        let demo = history(threshold: threshold, isDemo: true)

        #expect(demo.threshold == threshold)
        #expect(demo.isDemo)
        #expect(!history().isDemo)
    }

    // MARK: - CNIGHT-6: the days follow the calendar's time zone

    /// 9am UTC on the fourth day is 6pm in Tokyo, so the nights are Tokyo's days, each starting at 3pm UTC the day
    /// before, and a Tokyo bedtime of 10:30pm is 1:30pm UTC.
    @Test func theDaysFollowTheCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let nights = history(calendar: tokyo).nights

        #expect(nights.map(\.day) == [Self.date(-9), Self.date(15), Self.date(39)])
        #expect(nights.map(\.moment) == [Self.date(13.5), Self.date(37.5), Self.date(61.5)])
    }
}
