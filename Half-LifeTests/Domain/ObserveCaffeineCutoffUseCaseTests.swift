//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveCaffeineCutoffUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the cutoff streams what the repository publishes for the given calendar (OBSCUTOFF-1 in the
/// Caffeine Cutoff article).
struct ObserveCaffeineCutoffUseCaseTests {

    @Test func streamsTheCutoffsTheRepositoryPublishesForTheGivenCalendar() async throws {
        let bedtime = Date(timeIntervalSinceReferenceDate: 22.5 * 3_600)
        let before = CaffeineCutoff(
            drink: FavouriteDrink(type: .latte, quantity: 2), latestCup: Date(timeIntervalSinceReferenceDate: 47_160),
            bedtime: bedtime, threshold: .standard)
        let after = CaffeineCutoff(
            drink: FavouriteDrink(type: .latte, quantity: 2), latestCup: nil, bedtime: bedtime, threshold: .standard)
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeCaffeineDecayRepository(cutoffs: { $0.timeZone == tokyoTimeZone ? [before, after] : [] })
        let observe = ObserveCaffeineCutoffUseCase(repository: repository)

        var received: [CaffeineCutoff] = []
        for await cutoff in try await executeThroughProtocol(observe, tokyo) {
            received.append(cutoff)
        }

        #expect(received == [before, after])
    }
}
