//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FavouriteDrinksRepository
//

/// The source of truth for the one-tap favourites: the drinks the user logs most.
///
/// An implementation reads every logged drink from the drink data source, which it shares with
/// ``DrinkLogRepository`` and ``CaffeineDecayRepository``, and executes ``FavouriteDrinksRule`` on them. After each
/// change the data source signals, it re-reads the drinks and publishes the favourites again. The One-Tap Log article
/// lists its requirements, FAVREPO-1 to FAVREPO-3.
protocol FavouriteDrinksRepository: Sendable {
    /// Streams the favourites, most logged first, starting with the current ones.
    ///
    /// Each new subscriber immediately receives the current favourites. After that, every subscriber receives them
    /// again whenever the drink data source signals a change.
    func favourites() -> AsyncStream<[FavouriteDrink]>
}
