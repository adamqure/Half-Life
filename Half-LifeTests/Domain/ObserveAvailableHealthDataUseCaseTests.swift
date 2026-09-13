//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveAvailableHealthDataUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the available Health data streams the kinds the repository publishes for the last 30 days
/// in the given calendar (AVUSE-1 in the Insights article).
struct ObserveAvailableHealthDataUseCaseTests {

    @Test func streamsTheKindsTheRepositoryPublishesForTheLast30Days() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeHealthDataRepository(availableKinds: { days, calendar in
            days == 30 && calendar.timeZone == tokyoTimeZone ? [[], [.sleep, .steps]] : []
        })
        let observe = ObserveAvailableHealthDataUseCase(repository: repository)

        var received: [Set<HealthDataKind>] = []
        for await kinds in try await executeThroughProtocol(observe, tokyo) {
            received.append(kinds)
        }

        #expect(received == [[], [.sleep, .steps]])
    }
}
