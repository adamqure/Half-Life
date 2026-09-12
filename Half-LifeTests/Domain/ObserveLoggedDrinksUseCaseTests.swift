//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveLoggedDrinksUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks observing the drink log against the Drink Composer article: requirement OBSERVE-1.
struct ObserveLoggedDrinksUseCaseTests {

    // MARK: - OBSERVE-1: every set of drinks the repository publishes, in order

    @Test func streamsEverySetTheRepositoryPublishes() async throws {
        let first = LoggedDrink(
            type: .latte, quantity: 2, milligrams: 125.4, consumedAt: Date(timeIntervalSinceReferenceDate: 0))
        let second = LoggedDrink(
            type: .cola, quantity: 1, milligrams: 34, consumedAt: Date(timeIntervalSinceReferenceDate: 60))
        let observe = ObserveLoggedDrinksUseCase(
            repository: FakeDrinkLogRepository(drinks: [[first], [first, second]]))

        var received: [[LoggedDrink]] = []
        for await drinks in try await executeThroughProtocol(observe, ()) {
            received.append(drinks)
        }

        #expect(received == [[first], [first, second]])
    }
}
