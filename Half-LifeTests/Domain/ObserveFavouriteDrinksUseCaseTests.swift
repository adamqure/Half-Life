//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveFavouriteDrinksUseCaseTests
//

import Testing

@testable import Half_Life

/// Checks observing the favourites against the One-Tap Log article: requirement OBSFAV-1.
struct ObserveFavouriteDrinksUseCaseTests {

    // MARK: - OBSFAV-1: every set of favourites the repository publishes, in order

    @Test func streamsEverySetTheRepositoryPublishes() async throws {
        let first = [FavouriteDrink(type: .espresso, quantity: 2), FavouriteDrink(type: .flatWhite, quantity: 2)]
        let second = [FavouriteDrink(type: .matcha, quantity: 1), FavouriteDrink(type: .espresso, quantity: 2)]
        let observe = ObserveFavouriteDrinksUseCase(repository: FakeFavouriteDrinksRepository(sets: [first, second]))

        var received: [[FavouriteDrink]] = []
        for await favourites in try await executeThroughProtocol(observe, ()) {
            received.append(favourites)
        }

        #expect(received == [first, second])
    }
}
