//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveFavouriteDrinksUseCase
//

/// Streams the one-tap favourites, most logged first, starting with the current ones.
///
/// `OneTapLogFeature` observes it on the Today screen and in the drink composer. See the One-Tap Log article.
struct ObserveFavouriteDrinksUseCase: UseCase {
    /// The repository whose favourites are streamed.
    let repository: any FavouriteDrinksRepository

    /// Streams every set of favourites the repository publishes.
    ///
    /// - Parameter input: None.
    /// - Returns: The favourites, most logged first: the current ones, then new ones after each change.
    func execute(_ input: Void) -> AsyncStream<[FavouriteDrink]> {
        repository.favourites()
    }
}
