//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveCaffeineIntakeTodayUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing today's intake streams what the repository publishes for the given calendar (OBSINTAKE-1
/// in the Today Screen article).
struct ObserveCaffeineIntakeTodayUseCaseTests {

    @Test func streamsTheIntakesTheRepositoryPublishesForTheGivenCalendar() async throws {
        let morning = DailyCaffeineIntake(day: Date(timeIntervalSinceReferenceDate: 0), milligrams: 128)
        let afternoon = DailyCaffeineIntake(day: Date(timeIntervalSinceReferenceDate: 0), milligrams: 192)
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeDrinkLogRepository(intakes: { $0.timeZone == tokyoTimeZone ? [morning, afternoon] : [] })
        let observe = ObserveCaffeineIntakeTodayUseCase(repository: repository)

        var received: [DailyCaffeineIntake] = []
        for await intake in try await executeThroughProtocol(observe, tokyo) {
            received.append(intake)
        }

        #expect(received == [morning, afternoon])
    }
}
