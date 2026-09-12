//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FavouriteDrinksDependencyTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the favourites' dependency registrations: requirements FAVDEP-1 and FAVDEP-2 in the One-Tap Log article.
///
/// These tests use only the test values. The preview values open an in-memory SwiftData store, so the tests that read
/// them run inside the serialized `SwiftDataStoreTests` below.
struct FavouriteDrinksDependencyTests {

    /// FAVDEP-1: a test that observes the favourites without overriding `\.observeFavouriteDrinks` fails.
    @Test func observingTheFavouritesWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeFavouriteDrinks) var observeFavouriteDrinks
            for await _ in observeFavouriteDrinks.execute(()) {}
        }
    }

    /// FAVDEP-1: a test that uses the favourites repository without overriding `\.favouriteDrinksRepository` fails.
    @Test func usingTheRepositoryWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.favouriteDrinksRepository) var repository
            for await _ in repository.favourites() {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the favourites' preview registrations, which open an empty in-memory store. They run inside the
    /// serialized `SwiftDataStoreTests`, because they open a store.
    @Suite(.timeLimit(.minutes(1)))
    struct FavouriteDrinksPreviewDependencyTests {

        /// FAVDEP-2: the repository is the app's live repository.
        @Test func previewRepositoryIsTheLiveRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.favouriteDrinksRepository) var repository
                #expect(repository is LiveFavouriteDrinksRepository)
            }
        }

        /// FAVDEP-2: observing the favourites uses the one app-scoped favourites repository.
        @Test func previewObserveFavouriteDrinksUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.favouriteDrinksRepository) var repository
                @Dependency(\.observeFavouriteDrinks) var observeFavouriteDrinks
                #expect((observeFavouriteDrinks.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
