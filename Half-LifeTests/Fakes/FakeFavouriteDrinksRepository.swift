//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeFavouriteDrinksRepository
//

@testable import Half_Life

/// An in-memory favourites repository for use case and reducer tests.
///
/// It streams the sets of favourites it was given, then finishes. It's an actor, like the live repositories.
actor FakeFavouriteDrinksRepository: FavouriteDrinksRepository {
    /// The sets of favourites that `favourites()` streams, in order.
    let sets: [[FavouriteDrink]]

    init(sets: [[FavouriteDrink]] = []) {
        self.sets = sets
    }

    nonisolated func favourites() -> AsyncStream<[FavouriteDrink]> {
        AsyncStream { continuation in
            for set in sets {
                continuation.yield(set)
            }
            continuation.finish()
        }
    }
}
