//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepWindowRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks tonight's sleep window against SLEEPWIN-1 to SLEEPWIN-9 in the Insights article. The rule is pure, so its
/// tests need no fakes. They check it against ``CaffeineDecayRule``'s levels, so the window and the curve agree.
struct SleepWindowRuleTests {

    let rule = SleepWindowRule()
    let decay = CaffeineDecayRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    static let threshold = SleepThreshold.standard
    /// 6pm on the first day: the first night's evening, where its chart starts.
    static let evening = date(18)
    /// 10:30pm on the first day, the standard bedtime.
    static let bedtime = date(22.5)
    /// 4am on the second day, where the first night's chart ends unless the window runs later.
    static let morning = date(28)
    /// Noon on the second day, the latest the first night's caffeine is followed.
    static let noon = date(36)
    /// The brief's cold brew: 200 mg at 4pm. It clears at 5:06am, after 4am.
    static let coldBrew = [intake(200, hours: 16)]
    /// A two-shot latte at 3pm: 125.4 mg. It clears at 12:24am, after bedtime, and its window ends before 4am.
    static let afternoonLatte = [intake(125.4, hours: 15)]

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func intake(_ milligrams: Double, hours: Double) -> CaffeineIntake {
        CaffeineIntake(id: UUID(), milligrams: milligrams, consumedAt: date(hours))
    }

    func window(
        after intakes: [CaffeineIntake] = [], now: Date = date(17), bedtime: Bedtime = .standard,
        threshold: SleepThreshold = threshold, kinetics: CaffeineKinetics = .standard, calendar: Calendar = utc
    ) throws -> SleepWindow {
        let inputs = SleepWindowRule.Inputs(
            intakes: intakes, kinetics: kinetics, threshold: threshold, bedtime: bedtime)
        return try #require(rule.window(inputs, now: now, calendar: calendar))
    }

    func level(at date: Date, after intakes: [CaffeineIntake], kinetics: CaffeineKinetics = .standard) -> Double {
        decay.level(at: date, from: intakes, kinetics: kinetics).milligrams
    }

    // MARK: - SLEEPWIN-1: the night runs from 6pm to 4am, and from 4am, the coming night is shown

    /// From 4am to 6pm it's the coming night. From 6pm until 4am, it's the night already running.
    @Test(arguments: zip([17, 18, 23.5, 27.99, 28, 35], [18, 18, 18, 18, 42, 42]))
    func theNightIsTheOneRunningOrTheOneToCome(now: Double, evening: Double) throws {
        #expect(try window(now: Self.date(now)).evening == Self.date(evening))
    }

    /// The night follows the calendar's time zone: 5pm UTC is 2am in Tokyo, so the night began at 6pm Tokyo time.
    @Test func theNightFollowsTheCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        #expect(try window(now: Self.date(17), calendar: tokyo).evening == Self.date(9))
    }

    // MARK: - SLEEPWIN-2: caffeine clears at the first minute after which it stays at or below the threshold

    @Test func caffeineClearsAtTheFirstMinuteAfterWhichItStaysAtOrBelowTheThreshold() throws {
        let clearsAt = try #require(try window(after: Self.coldBrew).clearsAt)

        #expect(clearsAt.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) == 0)
        #expect(level(at: clearsAt, after: Self.coldBrew) <= Self.threshold.milligrams)
        #expect(level(at: clearsAt.addingTimeInterval(-60), after: Self.coldBrew) > Self.threshold.milligrams)
        #expect(clearsAt > Self.morning)
    }

    /// A cup at 8pm starts from nothing, rises over the threshold, and clears after it.
    @Test func aCupInTheEveningClearsAfterItsRise() throws {
        let evening = [Self.intake(120, hours: 20)]
        let window = try window(after: evening)
        let clearsAt = try #require(window.clearsAt)

        #expect(clearsAt > Self.date(21))
        #expect(level(at: clearsAt.addingTimeInterval(-60), after: evening) > Self.threshold.milligrams)
        #expect(
            window.levels.filter { $0.date >= clearsAt }.allSatisfy { $0.milligrams <= Self.threshold.milligrams })
    }

    /// With nothing over the threshold from 6pm on, caffeine has cleared by the evening.
    @Test func withNothingOverTheThresholdItHasClearedByTheEvening() throws {
        #expect(try window().clearsAt == Self.evening)
        #expect(try window(after: [Self.intake(125.4, hours: 8)]).clearsAt == Self.evening)
    }

    /// A higher threshold clears sooner. The window keeps the threshold it was found with.
    @Test func aHigherThresholdClearsSooner() throws {
        let higher = try #require(SleepThreshold(milligrams: 60))
        let window = try window(after: Self.coldBrew, threshold: higher)
        let clearsAt = try #require(window.clearsAt)

        #expect(try clearsAt < #require(try self.window(after: Self.coldBrew).clearsAt))
        #expect(level(at: clearsAt, after: Self.coldBrew) <= 60)
        #expect(window.threshold == higher)
    }

    // MARK: - SLEEPWIN-3: the bedtime is the first one at or after the evening

    @Test func theBedtimeIsTheFirstOneAtOrAfterTheEvening() throws {
        let afterMidnight = try #require(Bedtime(hour: 0, minute: 30))

        #expect(try window().bedtime == Self.bedtime)
        #expect(try window(bedtime: afterMidnight).bedtime == Self.date(24.5))
    }

    // MARK: - SLEEPWIN-4: clearing after bedtime, the window starts when caffeine clears and lasts 90 minutes

    @Test func clearingAfterBedtimeTheWindowStartsWhenCaffeineClears() throws {
        let window = try window(after: Self.afternoonLatte)
        let clearsAt = try #require(window.clearsAt)

        #expect(clearsAt > Self.bedtime)
        #expect(!window.clearsBeforeBedtime)
        #expect(window.window == DateInterval(start: clearsAt, duration: 90 * 60))
    }

    // MARK: - SLEEPWIN-5: clearing by bedtime, the window starts at bedtime

    /// 100 mg at 1pm is still 55 mg at 6pm, and clears at 8:36pm, before the 10:30pm bedtime.
    @Test func clearingByBedtimeTheWindowStartsAtBedtime() throws {
        let window = try window(after: [Self.intake(100, hours: 13)])
        let clearsAt = try #require(window.clearsAt)

        #expect(clearsAt > Self.evening)
        #expect(clearsAt < Self.bedtime)
        #expect(window.clearsBeforeBedtime)
        #expect(window.window == DateInterval(start: Self.bedtime, duration: 90 * 60))
    }

    @Test func withNoCaffeineTheWindowStartsAtBedtime() throws {
        let window = try window()

        #expect(window.clearsBeforeBedtime)
        #expect(window.window == DateInterval(start: Self.bedtime, duration: 90 * 60))
    }

    // MARK: - SLEEPWIN-6: the chart runs from 6pm to 4am, or to the window's end when that's later

    @Test func theChartEndsAt4amWhenTheWindowEndsByThen() throws {
        #expect(try window(after: Self.afternoonLatte).chartEnd == Self.morning)
    }

    @Test func theChartRunsToTheWindowsEndWhenThatsAfter4am() throws {
        let window = try window(after: Self.coldBrew)
        let end = try #require(window.window?.end)

        #expect(end > Self.morning)
        #expect(window.chartEnd == end)
    }

    // MARK: - SLEEPWIN-7: the chart has the level at every minute from the evening to its end, from the decay rule

    @Test func theChartHasTheCurvesLevelAtEveryMinute() throws {
        let window = try window(after: Self.coldBrew)
        let minutes = Int(window.chartEnd.timeIntervalSince(Self.evening) / 60)
        let expected = (0...minutes).map { minute in
            decay.level(
                at: Self.evening.addingTimeInterval(Double(minute) * 60), from: Self.coldBrew, kinetics: .standard)
        }

        #expect(window.levels == expected)
    }

    // MARK: - SLEEPWIN-8: caffeine that doesn't clear by noon gives no window, and a chart to noon

    /// With a 30-hour half-life, 400 mg at 5pm is still about 260 mg at noon the next day.
    @Test func caffeineThatDoesntClearByNoonGivesNoWindow() throws {
        let halfLife = try #require(CaffeineHalfLife(seconds: 30 * 3_600))
        let slow = CaffeineKinetics(halfLife: halfLife, absorption: .standard)
        let window = try window(after: [Self.intake(400, hours: 17)], kinetics: slow)

        #expect(window.clearsAt == nil)
        #expect(window.window == nil)
        #expect(!window.clearsBeforeBedtime)
        #expect(window.chartEnd == Self.noon)
        #expect(window.levels.last?.date == Self.noon)
    }

    // MARK: - SLEEPWIN-9: the window's times are whole minutes

    @Test func theWindowStartsOnAWholeMinute() throws {
        let start = try #require(try window(after: Self.afternoonLatte).window?.start)

        #expect(start.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) == 0)
    }
}
