//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveDrinkLogWeekUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the drink log's week streams the 7 days before today, yesterday last, for the given calendar
/// (WEEKUSE-1 in the Insights article).
struct ObserveDrinkLogWeekUseCaseTests {

    static func day(_ index: Int, milligrams: Double) -> DrinkLogDay {
        DrinkLogDay(
            intake: DailyCaffeineIntake(
                day: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400), milligrams: milligrams),
            drinks: [])
    }

    /// The repository's 8 days to today lose today. A change to today alone sends nothing, and the next day's 8 days
    /// send the next 7.
    @Test func streamsTheSevenDaysBeforeTodayForTheGivenCalendar() async throws {
        let eight = (0..<8).map { Self.day($0, milligrams: Double($0) * 10) }
        let laterToday = Array(eight.dropLast()) + [Self.day(7, milligrams: 200)]
        let nextDay = (1..<9).map { Self.day($0, milligrams: Double($0) * 10) }
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeDrinkLogRepository(recentDays: { count, calendar in
            count == 8 && calendar.timeZone == tokyoTimeZone ? [eight, laterToday, nextDay] : []
        })
        let observe = ObserveDrinkLogWeekUseCase(repository: repository)

        var received: [[DrinkLogDay]] = []
        for await days in try await executeThroughProtocol(observe, tokyo) {
            received.append(days)
        }

        #expect(received == [Array(eight.dropLast()), Array(nextDay.dropLast())])
    }
}
