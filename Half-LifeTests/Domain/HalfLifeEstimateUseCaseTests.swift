//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HalfLifeEstimateUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that each half-life estimate use case performs its one operation on the estimate repository.
struct HalfLifeEstimateUseCaseTests {

    static func estimate(nights: Int) throws -> HalfLifeEstimate {
        HalfLifeEstimate(
            halfLife: .standard, lowerBound: try #require(CaffeineHalfLife(seconds: 12_000)),
            upperBound: try #require(CaffeineHalfLife(seconds: 33_000)), prior: .standard, nightsUsed: nights,
            calculatedAt: Date(timeIntervalSinceReferenceDate: 0))
    }

    @Test func observeStreamsEveryEstimateInOrder() async throws {
        let published = [try Self.estimate(nights: 0), try Self.estimate(nights: 14)]
        let observe = ObserveHalfLifeEstimateUseCase(repository: FakeHalfLifeEstimateRepository(streamed: published))

        var received: [HalfLifeEstimate] = []
        for await estimate in try await executeThroughProtocol(observe, ()) {
            received.append(estimate)
        }

        #expect(received == published)
    }

    @Test func refreshAsksTheRepositoryOnce() async throws {
        let repository = FakeHalfLifeEstimateRepository()

        try await executeThroughProtocol(RefreshHalfLifeEstimateUseCase(repository: repository), ())

        #expect(await repository.refreshCount == 1)
    }
}
