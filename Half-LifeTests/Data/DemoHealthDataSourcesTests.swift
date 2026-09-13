//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoHealthDataSourcesTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the demo sleep, step count, and resting heart rate data sources against DEMOHEALTH-1 to DEMOHEALTH-6 in the
/// Apple Health Card article.
///
/// "Now" is 9:30am on June 15, 2026, in New York, where the clocks don't change in the 30 days before it.
struct DemoHealthDataSourcesTests {
    let calendar: Calendar
    let now: Date

    init() throws {
        calendar = try Self.calendar("America/New_York")
        now = try Self.date(calendar, hour: 9, minute: 30)
    }

    static func calendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    /// A local time on June 15, 2026, or on the day `daysAgo` before it, in `calendar`.
    static func date(_ calendar: Calendar, daysAgo: Int = 0, hour: Int, minute: Int = 0) throws -> Date {
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15 - daysAgo)))
        return try #require(calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day))
    }

    func date(daysAgo: Int = 0, hour: Int, minute: Int = 0) throws -> Date {
        try Self.date(calendar, daysAgo: daysAgo, hour: hour, minute: minute)
    }

    func sleep(at now: Date, in calendar: Calendar? = nil) -> DemoSleepDataSource {
        DemoSleepDataSource(clock: FakeClockDataSource(date: now, minuteDates: []), calendar: calendar ?? self.calendar)
    }

    func steps(at now: Date, minutes: [Date] = []) -> DemoStepCountDataSource {
        DemoStepCountDataSource(clock: FakeClockDataSource(date: now, minuteDates: minutes), calendar: calendar)
    }

    func restingHeartRate(at now: Date) -> DemoRestingHeartRateDataSource {
        DemoRestingHeartRateDataSource(clock: FakeClockDataSource(date: now, minuteDates: []), calendar: calendar)
    }

    /// Last night on the morning `daysAgo` before June 15, as the Apple Health card finds it.
    func lastNight(daysAgo: Int) async throws -> LastNightSleep? {
        let morning = try date(daysAgo: daysAgo, hour: 9)
        let rule = LastNightSleepRule()
        let window = try #require(rule.night(containing: morning, calendar: calendar))
        let intervals = try await sleep(at: now).sleepIntervals(
            in: DateInterval(start: window.start.addingTimeInterval(-86_400), end: window.end))
        return rule.lastNight(from: intervals, at: morning, calendar: calendar)
    }

    // MARK: - DEMOHEALTH-1: every night of the last 30 has sleep, except the in-bed night, and none comes before

    @Test func everyNightOfTheLastThirtyHasSleepExceptTheInBedNight() async throws {
        for daysAgo in 0...30 where daysAgo != 10 {
            let lastNight = try await lastNight(daysAgo: daysAgo)
            guard case .asleep = lastNight else {
                Issue.record("The night \(daysAgo) nights ago is \(String(describing: lastNight)), not sleep.")
                continue
            }
        }
    }

    @Test func nothingComesBeforeTheThirtyNights() async throws {
        let before = DateInterval(start: try date(daysAgo: 45, hour: 0), end: try date(daysAgo: 31, hour: 12))

        #expect(try await sleep(at: now).sleepIntervals(in: before).isEmpty)
    }

    // MARK: - DEMOHEALTH-2: nights after late cups start later and have less deep sleep

    @Test func nightsAfterLateCupsStartLaterWithLessDeepSleep() async throws {
        let drinks = DemoHistoryRule().drinks(now: now, calendar: calendar)
        let drinkDays = Set(drinks.map { calendar.startOfDay(for: $0.consumedAt) })
        let lateDays = Set(
            drinks.filter { calendar.component(.hour, from: $0.consumedAt) >= 15 && $0.milligrams >= 90 }
                .map { calendar.startOfDay(for: $0.consumedAt) })
        let afternoonDays = Set(
            drinks.filter { calendar.component(.hour, from: $0.consumedAt) >= 15 }
                .map { calendar.startOfDay(for: $0.consumedAt) })
        let earlyDays = drinkDays.subtracting(afternoonDays)
        let intervals = try await sleep(at: now).sleepIntervals(
            in: DateInterval(start: try date(daysAgo: 32, hour: 0), end: now))

        // Each night, with how long after noon on the day before it the user fell asleep.
        var late: [(night: SleepNight, onsetAfterNoon: TimeInterval)] = []
        var early: [(night: SleepNight, onsetAfterNoon: TimeInterval)] = []
        for night in SleepNightRule().nights(from: intervals) {
            let drinkDay = try #require(
                calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: night.wake)))
            let noon = try #require(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: drinkDay))
            let entry = (night: night, onsetAfterNoon: night.sleepOnset.timeIntervalSince(noon))
            if lateDays.contains(drinkDay) {
                late.append(entry)
            } else if earlyDays.contains(drinkDay) {
                early.append(entry)
            }
        }

        try #require(!late.isEmpty && !early.isEmpty)
        let lateDeepest = try #require(late.map(\.night.deepSeconds).max())
        let earlyLightest = try #require(early.map(\.night.deepSeconds).min())
        let lateEarliestOnset = try #require(late.map(\.onsetAfterNoon).min())
        let earlyLatestOnset = try #require(early.map(\.onsetAfterNoon).max())
        #expect(lateDeepest < earlyLightest)
        #expect(lateEarliestOnset > earlyLatestOnset)
    }

    // MARK: - DEMOHEALTH-3: the night 10 nights ago has time in bed and no sleep

    @Test func theNightTenNightsAgoIsInBedOnly() async throws {
        guard case .inBedOnly = try await lastNight(daysAgo: 10) else {
            Issue.record("The night 10 nights ago isn't time in bed only.")
            return
        }
    }

    // MARK: - DEMOHEALTH-4: today's steps grow with the clock, and the step source signals every minute

    @Test func todaysStepsGrowWithTheClock() async throws {
        func stepsToday(atHour hour: Int, minute: Int = 0) async throws -> Int? {
            let moment = try date(hour: hour, minute: minute)
            return try await steps(at: moment).stepCount(on: moment)
        }

        let beforeSeven = try await stepsToday(atHour: 6, minute: 59)
        let atSeven = try await stepsToday(atHour: 7)
        let atNoon = try #require(try await stepsToday(atHour: 12))
        let atTen = try #require(try await stepsToday(atHour: 22))
        let atEleven = try await stepsToday(atHour: 23)

        #expect(beforeSeven == nil)
        #expect(atSeven == 0)
        #expect(atNoon > 0 && atNoon < atTen)
        #expect(atEleven == atTen)
    }

    @Test func pastDaysHaveTheirTotalsAndNothingComesBefore() async throws {
        let source = steps(at: now)

        for daysAgo in 1...30 {
            let total = try #require(try await source.stepCount(on: try date(daysAgo: daysAgo, hour: 12)))
            #expect((4_000...12_500).contains(total))
        }
        #expect(try await source.stepCount(on: try date(daysAgo: 31, hour: 12)) == nil)
    }

    @Test func theStepSourceSignalsAtEveryMinute() async throws {
        let minutes = [try date(hour: 9, minute: 31), try date(hour: 9, minute: 32), try date(hour: 9, minute: 33)]
        var count = 0

        for await _ in steps(at: now, minutes: minutes).changes() {
            count += 1
        }

        #expect(count == 3)
    }

    // MARK: - DEMOHEALTH-5: today has no resting heart rate before 9am

    @Test func todayHasNoRestingHeartRateBeforeNine() async throws {
        let beforeNine = try date(hour: 8, minute: 59)
        let atNine = try date(hour: 9)

        #expect(try await restingHeartRate(at: beforeNine).averageRestingHeartRate(on: beforeNine) == nil)
        #expect(try await restingHeartRate(at: atNine).averageRestingHeartRate(on: atNine) != nil)
    }

    @Test func pastDaysHaveARestingHeartRateAndNothingComesBefore() async throws {
        let source = restingHeartRate(at: now)

        for daysAgo in 1...30 {
            let average = try #require(
                try await source.averageRestingHeartRate(on: try date(daysAgo: daysAgo, hour: 12)))
            #expect((50...70).contains(average))
        }
        #expect(try await source.averageRestingHeartRate(on: try date(daysAgo: 31, hour: 12)) == nil)
    }

    // MARK: - DEMOHEALTH-6: the same day gives the same values, at the same local clock times in any time zone

    @Test func theSameDayGivesTheSameValuesAtTheSameLocalTimesInAnyTimeZone() async throws {
        let tokyo = try Self.calendar("Asia/Tokyo")
        let tokyoNow = try Self.date(tokyo, hour: 9, minute: 30)
        func localTimes(_ intervals: [SleepStageInterval], in calendar: Calendar) -> [String] {
            intervals.map { interval in
                let start = calendar.dateComponents([.day, .hour, .minute], from: interval.start)
                let end = calendar.dateComponents([.day, .hour, .minute], from: interval.end)
                return "\(interval.stage) \(start.day ?? 0) \(start.hour ?? 0):\(start.minute ?? 0)-"
                    + "\(end.day ?? 0) \(end.hour ?? 0):\(end.minute ?? 0)"
            }
        }
        let newYorkRange = DateInterval(start: try date(daysAgo: 3, hour: 0), end: now)
        let tokyoRange = DateInterval(start: try Self.date(tokyo, daysAgo: 3, hour: 0), end: tokyoNow)

        let newYorkNights = try await sleep(at: now).sleepIntervals(in: newYorkRange)
        let againNights = try await sleep(at: now).sleepIntervals(in: newYorkRange)
        let tokyoNights = try await sleep(at: tokyoNow, in: tokyo).sleepIntervals(in: tokyoRange)

        #expect(!newYorkNights.isEmpty)
        #expect(newYorkNights == againNights)
        #expect(localTimes(newYorkNights, in: calendar) == localTimes(tokyoNights, in: tokyo))
    }
}
