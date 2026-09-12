//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveCaffeineStatusUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the caffeine status streams what the repository publishes for the given calendar.
struct ObserveCaffeineStatusUseCaseTests {

    @Test func streamsTheStatusesTheRepositoryPublishesForTheGivenCalendar() async throws {
        let status = CaffeineStatus(
            level: CaffeineLevel(date: Date(timeIntervalSinceReferenceDate: 0), milligrams: 85),
            activeIntakes: [], lastIntakeHalfGoneAt: nil, levelAtBedtime: nil)
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeCaffeineDecayRepository(statuses: { $0.timeZone == tokyoTimeZone ? [status] : [] })
        let observe = ObserveCaffeineStatusUseCase(repository: repository)

        var received: [CaffeineStatus] = []
        for await published in try await executeThroughProtocol(observe, tokyo) {
            received.append(published)
        }

        #expect(received == [status])
    }
}
