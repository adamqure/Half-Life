//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveTimeOfDayUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the time of day turns each minute of the current time into a ``TimeOfDay`` (TOD-1 and
/// TOD-2 in the Today Screen article).
struct ObserveTimeOfDayUseCaseTests {

    private func calendar(in timeZone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        return calendar
    }

    /// TOD-1: each minute the repository streams becomes a time of day with the period from ``DayPeriodRule``.
    @Test func streamsEachMinuteWithItsDayPeriod() async throws {
        let utc = try calendar(in: "UTC")
        let afternoon = try #require(
            utc.date(from: DateComponents(year: 2026, month: 9, day: 11, hour: 15, minute: 24)))
        let observe = ObserveTimeOfDayUseCase(currentTime: FakeCurrentTimeRepository(date: afternoon))

        var received: [TimeOfDay] = []
        for await timeOfDay in try await executeThroughProtocol(observe, utc) {
            received.append(timeOfDay)
        }

        #expect(received == [TimeOfDay(date: afternoon, period: .afternoon)])
    }

    /// TOD-2: the period is found in the calendar passed in. 01:00 UTC is 10:00 in Tokyo.
    @Test func findsThePeriodInTheGivenCalendar() async throws {
        let instant = try #require(
            try calendar(in: "UTC").date(from: DateComponents(year: 2026, month: 9, day: 11, hour: 1))
        )
        let observe = ObserveTimeOfDayUseCase(currentTime: FakeCurrentTimeRepository(date: instant))

        var received: [TimeOfDay] = []
        for await timeOfDay in try await executeThroughProtocol(observe, try calendar(in: "Asia/Tokyo")) {
            received.append(timeOfDay)
        }

        #expect(received == [TimeOfDay(date: instant, period: .morning)])
    }
}
