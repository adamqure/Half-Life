//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogHistoryDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the history card's dependency registrations with their test values. Reading the live or preview values
/// would open a SwiftData store in the test host.
struct DrinkLogHistoryDependencyTests {

    /// A test that observes a day of the log without overriding `\.observeDrinkLogDay` fails.
    @Test func observingADayWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeDrinkLogDay) var observeDrinkLogDay
            let input = ObserveDrinkLogDayUseCase.Input(
                date: Date(timeIntervalSinceReferenceDate: 0), calendar: Calendar(identifier: .gregorian))
            for await _ in observeDrinkLogDay.execute(input) {}
        }
    }

    /// A test that deletes a drink without overriding `\.deleteDrink` fails.
    @Test func deletingADrinkWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.deleteDrink) var deleteDrink
            try? await deleteDrink.execute(UUID())
        }
    }

    /// A test that observes a day through the drink log without overriding `\.drinkLogRepository` fails.
    @Test func observingADayThroughTheDrinkLogWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.drinkLogRepository) var drinkLog
            let day = drinkLog.day(
                containing: Date(timeIntervalSinceReferenceDate: 0), in: Calendar(identifier: .gregorian))
            for await _ in day {}
        }
    }

    /// A test that deletes through the drink log without overriding `\.drinkLogRepository` fails.
    @Test func deletingThroughTheDrinkLogWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.drinkLogRepository) var drinkLog
            try? await drinkLog.delete(UUID())
        }
    }

    /// A test that deletes through the drink log data source without overriding a repository fails.
    @Test func deletingThroughTheDataSourceWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            try? await DrinkLogDataSourceKey.testValue.delete(UUID())
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the history card's preview registrations, which open an empty in-memory store. They run inside the
    /// serialized `SwiftDataStoreTests`, because they open a store.
    @Suite(.timeLimit(.minutes(1)))
    struct DrinkLogHistoryPreviewDependencyTests {

        /// DEP-6: observing a day of the log uses the one app-scoped drink log repository.
        @Test func previewObserveDrinkLogDayUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.drinkLogRepository) var repository
                @Dependency(\.observeDrinkLogDay) var observeDrinkLogDay
                #expect((observeDrinkLogDay.repository as AnyObject) === (repository as AnyObject))
            }
        }

        /// DEP-6: deleting a drink uses the one app-scoped drink log repository.
        @Test func previewDeleteDrinkUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.drinkLogRepository) var repository
                @Dependency(\.deleteDrink) var deleteDrink
                #expect((deleteDrink.drinkLog as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
