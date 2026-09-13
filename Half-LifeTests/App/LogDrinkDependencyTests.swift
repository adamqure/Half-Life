//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LogDrinkDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the drink log's dependency registrations.
///
/// These tests use only the test values. Reading the live or preview values would open a SwiftData store in the test
/// host, and the live one would open the device's store.
struct LogDrinkDependencyTests {

    /// A test that logs a drink without overriding `\.logDrink` fails.
    @Test func loggingADrinkWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.logDrink) var logDrink
            try? await logDrink.execute(LogDrinkUseCase.Input(type: .latte, quantity: 1, secondsAgo: 0))
        }
    }

    /// A test that observes the logged drinks without overriding `\.observeLoggedDrinks` fails.
    @Test func observingLoggedDrinksWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeLoggedDrinks) var observeLoggedDrinks
            for await _ in observeLoggedDrinks.execute(()) {}
        }
    }

    /// A test that observes the drink log without overriding `\.drinkLogRepository` fails.
    @Test func observingTheDrinkLogWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.drinkLogRepository) var drinkLog
            for await _ in drinkLog.loggedDrinks() {}
        }
    }

    /// A test that logs through the drink log without overriding `\.drinkLogRepository` fails.
    @Test func loggingThroughTheDrinkLogWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.drinkLogRepository) var drinkLog
            try? await drinkLog.log(
                LoggedDrink(
                    type: .cola, quantity: 1, milligrams: 34, consumedAt: Date(timeIntervalSinceReferenceDate: 0)))
        }
    }

    /// A test that observes today's intake without overriding `\.observeCaffeineIntakeToday` fails.
    @Test func observingTodaysIntakeWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeCaffeineIntakeToday) var observeCaffeineIntakeToday
            for await _ in observeCaffeineIntakeToday.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes today's intake through the drink log without overriding `\.drinkLogRepository` fails.
    @Test func observingTodaysIntakeThroughTheDrinkLogWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.drinkLogRepository) var drinkLog
            for await _ in drinkLog.intakeToday(in: Calendar(identifier: .gregorian)) {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the drink log's preview registrations, which open an empty in-memory store. They run inside the
    /// serialized `SwiftDataStoreTests`, because they open a store.
    @Suite(.timeLimit(.minutes(1)))
    struct DrinkLogPreviewDependencyTests {

        /// DEP-5: observing today's intake uses the one app-scoped drink log repository.
        @Test func previewObserveCaffeineIntakeTodayUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.drinkLogRepository) var repository
                @Dependency(\.observeCaffeineIntakeToday) var observeCaffeineIntakeToday
                #expect((observeCaffeineIntakeToday.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
