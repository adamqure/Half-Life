//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveDrinkLogDayUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks observing one day of the drink log against HISTUSE-1 in the Today Screen article.
struct ObserveDrinkLogDayUseCaseTests {

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)

    // MARK: - HISTUSE-1: every day the repository publishes for the date and calendar, in order

    @Test func streamsEveryDayTheRepositoryPublishesForTheDateAndCalendar() async throws {
        var tokyoCalendar = Calendar(identifier: .gregorian)
        tokyoCalendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        // A constant, so the repository's `@Sendable` closure can capture it.
        let tokyo = tokyoCalendar
        let noon = Self.midnight.addingTimeInterval(12 * 3_600)
        let drink = LoggedDrink(type: .latte, quantity: 2, milligrams: 125.4, consumedAt: noon)
        let empty = DrinkLogDay(intake: DailyCaffeineIntake(day: Self.midnight, milligrams: 0), drinks: [])
        let logged = DrinkLogDay(intake: DailyCaffeineIntake(day: Self.midnight, milligrams: 125.4), drinks: [drink])
        let repository = FakeDrinkLogRepository(days: { date, calendar in
            date == noon && calendar == tokyo ? [empty, logged] : []
        })

        var received: [DrinkLogDay] = []
        let input = ObserveDrinkLogDayUseCase.Input(date: noon, calendar: tokyo)
        for await day in try await executeThroughProtocol(ObserveDrinkLogDayUseCase(repository: repository), input) {
            received.append(day)
        }

        #expect(received == [empty, logged])
    }
}
