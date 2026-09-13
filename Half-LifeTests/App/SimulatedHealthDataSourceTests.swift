//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SimulatedHealthDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data a UI test's app holds (SIMHEALTH-1 in the Apple Health Card article).
struct SimulatedHealthDataSourceTests {
    let calendar: Calendar
    let now: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        self.calendar = calendar
        now = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 9)))
    }

    func source(holding data: Set<SimulatedHealthData>) -> SimulatedHealthDataSource {
        SimulatedHealthDataSource(
            holding: data, clock: FakeClockDataSource(date: now, minuteDates: []), calendar: calendar)
    }

    func lastNight(in source: SimulatedHealthDataSource) async throws -> LastNightSleep? {
        let rule = LastNightSleepRule()
        let window = try #require(rule.night(containing: now, calendar: calendar))
        let intervals = try await source.sleepIntervals(
            in: DateInterval(start: window.start.addingTimeInterval(-86_400), end: window.end))
        return rule.lastNight(from: intervals, at: now, calendar: calendar)
    }

    /// SIMHEALTH-1: it holds exactly the Health data it's given.
    @Test func holdsExactlyTheGivenHealthData() async throws {
        let none = source(holding: [])
        let all = source(holding: [.sleep, .steps, .heartRate])
        let inBed = source(holding: [.inBed])

        #expect(try await lastNight(in: none) == nil)
        #expect(try await none.stepCount(on: now) == nil)
        #expect(try await none.averageRestingHeartRate(on: now) == nil)
        #expect(try await lastNight(in: all) == .asleep(seconds: 7 * 3_600))
        #expect(try await all.stepCount(on: now) == 8_420)
        #expect(try await all.averageRestingHeartRate(on: now) == 58)
        #expect(try await lastNight(in: inBed) == .inBedOnly(seconds: 8 * 3_600))
    }

    /// SIMHEALTH-1: its data never changes, so its change stream finishes at once.
    @Test func itsDataNeverChanges() async {
        var count = 0
        for await _ in source(holding: [.steps]).changes() {
            count += 1
        }

        #expect(count == 0)
    }
}
