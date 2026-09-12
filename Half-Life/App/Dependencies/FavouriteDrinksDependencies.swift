//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FavouriteDrinksDependencies
//

import ComposableArchitecture

extension DependencyValues {
    /// The app's favourites repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveFavouriteDrinksRepository`` over the shared drink log data source, which the
    /// drink log and caffeine decay repositories read too. In previews, it's the same repository over an empty
    /// in-memory store. In tests, using it without overriding it reports an issue.
    var favouriteDrinksRepository: any FavouriteDrinksRepository {
        get { self[FavouriteDrinksRepositoryKey.self] }
        set { self[FavouriteDrinksRepositoryKey.self] = newValue }
    }

    /// Observes the one-tap favourites through the app-scoped ``favouriteDrinksRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeFavouriteDrinks: ObserveFavouriteDrinksUseCase {
        get { self[ObserveFavouriteDrinksUseCaseKey.self] }
        set { self[ObserveFavouriteDrinksUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped favourites repository. It's private, because only the use case in this file is built
/// from it.
private enum FavouriteDrinksRepositoryKey: DependencyKey {
    static let liveValue: any FavouriteDrinksRepository = LiveFavouriteDrinksRepository(
        dataSource: DrinkLogDataSourceKey.liveValue)
    static let previewValue: any FavouriteDrinksRepository = LiveFavouriteDrinksRepository(
        dataSource: DrinkLogDataSourceKey.previewValue)
    static let testValue: any FavouriteDrinksRepository = UnimplementedFavouriteDrinksRepository()
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveFavouriteDrinksUseCaseKey: DependencyKey {
    static let liveValue = ObserveFavouriteDrinksUseCase(repository: FavouriteDrinksRepositoryKey.liveValue)
    static let previewValue = ObserveFavouriteDrinksUseCase(repository: FavouriteDrinksRepositoryKey.previewValue)
    static let testValue = ObserveFavouriteDrinksUseCase(repository: FavouriteDrinksRepositoryKey.testValue)
}

/// The favourites repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedFavouriteDrinksRepository: FavouriteDrinksRepository {
    func favourites() -> AsyncStream<[FavouriteDrink]> {
        reportIssue(
            "A test observed the favourites without overriding \\.favouriteDrinksRepository or "
                + "\\.observeFavouriteDrinks.")
        return AsyncStream { $0.finish() }
    }
}
