//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogDependencies
//

import ComposableArchitecture
import Foundation

extension DependencyValues {
    /// The app's drink log repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveDrinkLogRepository`` over the shared drink log data source, which the caffeine
    /// decay repository reads too. In previews, it's the same repository over an empty in-memory store. In tests,
    /// using it without overriding it reports an issue.
    var drinkLogRepository: any DrinkLogRepository {
        get { self[DrinkLogRepositoryKey.self] }
        set { self[DrinkLogRepositoryKey.self] = newValue }
    }

    /// Logs a drink through the app-scoped ``drinkLogRepository``, with the time from ``currentTimeRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var logDrink: LogDrinkUseCase {
        get { self[LogDrinkUseCaseKey.self] }
        set { self[LogDrinkUseCaseKey.self] = newValue }
    }

    /// Observes every logged drink through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeLoggedDrinks: ObserveLoggedDrinksUseCase {
        get { self[ObserveLoggedDrinksUseCaseKey.self] }
        set { self[ObserveLoggedDrinksUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped drink log repository.
///
/// It's internal so that every use case built on the drink log can be built from these values directly, as the
/// Architecture article's "Registering a repository and its use cases" explains.
enum DrinkLogRepositoryKey: DependencyKey {
    /// The one app-scoped repository, over the shared drink log data source and the system clock.
    static let liveValue: any DrinkLogRepository = LiveDrinkLogRepository(
        dataSource: DrinkLogDataSourceKey.liveValue, clock: SystemClockDataSource())
    /// The same repository over an empty in-memory store, so previews never touch the user's drinks.
    static let previewValue: any DrinkLogRepository = LiveDrinkLogRepository(
        dataSource: DrinkLogDataSourceKey.previewValue, clock: SystemClockDataSource())
    /// A repository that reports an issue when a test uses it without overriding it.
    static let testValue: any DrinkLogRepository = UnimplementedDrinkLogRepository()
}

private enum LogDrinkUseCaseKey: DependencyKey {
    static let liveValue = LogDrinkUseCase(
        currentTime: CurrentTimeRepositoryKey.liveValue, drinkLog: DrinkLogRepositoryKey.liveValue)
    static let previewValue = LogDrinkUseCase(
        currentTime: CurrentTimeRepositoryKey.previewValue, drinkLog: DrinkLogRepositoryKey.previewValue)
    static let testValue = LogDrinkUseCase(
        currentTime: CurrentTimeRepositoryKey.testValue, drinkLog: DrinkLogRepositoryKey.testValue)
}

private enum ObserveLoggedDrinksUseCaseKey: DependencyKey {
    static let liveValue = ObserveLoggedDrinksUseCase(repository: DrinkLogRepositoryKey.liveValue)
    static let previewValue = ObserveLoggedDrinksUseCase(repository: DrinkLogRepositoryKey.previewValue)
    static let testValue = ObserveLoggedDrinksUseCase(repository: DrinkLogRepositoryKey.testValue)
}

/// The error an unimplemented dependency throws after reporting its issue.
private struct UnimplementedDependency: Error {}

/// The drink log repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedDrinkLogRepository: DrinkLogRepository {
    func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        reportIssue("A test observed the drink log without overriding \\.drinkLogRepository or \\.observeLoggedDrinks.")
        return AsyncStream { $0.finish() }
    }

    func log(_ drink: LoggedDrink) async throws {
        reportIssue("A test logged a drink without overriding \\.drinkLogRepository or \\.logDrink.")
        throw UnimplementedDependency()
    }
}
