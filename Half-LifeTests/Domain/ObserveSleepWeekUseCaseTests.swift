//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveSleepWeekUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the sleep week streams the nights after the 7 days before today, yesterday's last, for the
/// given calendar (SLEEPUSE-1 in the Insights article).
struct ObserveSleepWeekUseCaseTests {

    /// The repository's 8 nights to tonight lose tonight's, which hasn't happened. Each history that changes the 7
    /// before it is sent, and one that doesn't isn't.
    @Test func streamsTheNightsAfterTheSevenDaysBeforeTodayForTheGivenCalendar() async throws {
        let nights = (0..<8).map { index in
            SleepHistoryNight(
                day: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400),
                sleep: index == 7 ? nil : .asleep(seconds: 7 * 3_600))
        }
        let live = SleepHistory(nights: nights, isDemo: false)
        let demo = SleepHistory(nights: nights, isDemo: true)
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeHealthDataRepository(histories: { days, calendar in
            days == 8 && calendar.timeZone == tokyoTimeZone ? [live, live, demo] : []
        })
        let observe = ObserveSleepWeekUseCase(repository: repository)

        var received: [SleepHistory] = []
        for await history in try await executeThroughProtocol(observe, tokyo) {
            received.append(history)
        }

        #expect(
            received == [
                SleepHistory(nights: Array(nights.dropLast()), isDemo: false),
                SleepHistory(nights: Array(nights.dropLast()), isDemo: true),
            ])
    }
}
