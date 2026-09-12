//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveCaffeineCurveUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the curve streams exactly what the repository publishes.
struct ObserveCaffeineCurveUseCaseTests {

    @Test func streamsEveryCurveTheRepositoryPublishesInOrder() async throws {
        let midnight = Date(timeIntervalSinceReferenceDate: 0)
        let first = [CaffeineLevel(date: midnight, milligrams: 128)]
        let second = [CaffeineLevel(date: midnight, milligrams: 192)]
        let observe = ObserveCaffeineCurveUseCase(repository: FakeCaffeineDecayRepository(curves: [first, second]))

        var received: [[CaffeineLevel]] = []
        for await curve in try await executeThroughProtocol(observe, ()) {
            received.append(curve)
        }

        #expect(received == [first, second])
    }
}
