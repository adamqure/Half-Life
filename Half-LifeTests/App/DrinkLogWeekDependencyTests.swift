//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogWeekDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the drink log week's test registrations (constitution Article I.15, DEP-WEEK in the Insights article). None
/// of these tests opens a store.
struct DrinkLogWeekDependencyTests {

    /// A test that observes the recent days without overriding the repository fails.
    @Test func testDrinkLogRepositoryRecentDaysReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.drinkLogRepository) var repository
            for await _ in repository.recentDays(7, in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the week without overriding the use case fails.
    @Test func testObserveDrinkLogWeekReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeDrinkLogWeek) var observeDrinkLogWeek
            for await _ in observeDrinkLogWeek.execute(Calendar(identifier: .gregorian)) {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the week's preview registration, which opens an empty in-memory store. It runs inside the serialized
    /// `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct DrinkLogWeekPreviewDependencyTests {

        /// DEP-WEEK: observing the week uses the one app-scoped drink log repository.
        @Test func previewObserveDrinkLogWeekUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.drinkLogRepository) var repository
                @Dependency(\.observeDrinkLogWeek) var observeDrinkLogWeek
                #expect((observeDrinkLogWeek.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
