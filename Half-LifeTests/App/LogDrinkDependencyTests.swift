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
/// host, and the live one would reach CloudKit.
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
}
