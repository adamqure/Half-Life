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

    /// Observes the caffeine logged today through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeCaffeineIntakeToday: ObserveCaffeineIntakeTodayUseCase {
        get { self[ObserveCaffeineIntakeTodayUseCaseKey.self] }
        set { self[ObserveCaffeineIntakeTodayUseCaseKey.self] = newValue }
    }

    /// Observes one day of the drink log through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeDrinkLogDay: ObserveDrinkLogDayUseCase {
        get { self[ObserveDrinkLogDayUseCaseKey.self] }
        set { self[ObserveDrinkLogDayUseCaseKey.self] = newValue }
    }

    /// Observes the last 7 days of the drink log through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeDrinkLogWeek: ObserveDrinkLogWeekUseCase {
        get { self[ObserveDrinkLogWeekUseCaseKey.self] }
        set { self[ObserveDrinkLogWeekUseCaseKey.self] = newValue }
    }

    /// Deletes a drink through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var deleteDrink: DeleteDrinkUseCase {
        get { self[DeleteDrinkUseCaseKey.self] }
        set { self[DeleteDrinkUseCaseKey.self] = newValue }
    }

    /// Adds the demo history through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var addDemoHistory: AddDemoHistoryUseCase {
        get { self[AddDemoHistoryUseCaseKey.self] }
        set { self[AddDemoHistoryUseCaseKey.self] = newValue }
    }

    /// Removes the demo history through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var removeDemoHistory: RemoveDemoHistoryUseCase {
        get { self[RemoveDemoHistoryUseCaseKey.self] }
        set { self[RemoveDemoHistoryUseCaseKey.self] = newValue }
    }

    /// Observes whether the drink log holds demo drinks through the app-scoped ``drinkLogRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeDemoHistory: ObserveDemoHistoryUseCase {
        get { self[ObserveDemoHistoryUseCaseKey.self] }
        set { self[ObserveDemoHistoryUseCaseKey.self] = newValue }
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

private enum ObserveCaffeineIntakeTodayUseCaseKey: DependencyKey {
    static let liveValue = ObserveCaffeineIntakeTodayUseCase(repository: DrinkLogRepositoryKey.liveValue)
    static let previewValue = ObserveCaffeineIntakeTodayUseCase(repository: DrinkLogRepositoryKey.previewValue)
    static let testValue = ObserveCaffeineIntakeTodayUseCase(repository: DrinkLogRepositoryKey.testValue)
}

private enum ObserveDrinkLogDayUseCaseKey: DependencyKey {
    static let liveValue = ObserveDrinkLogDayUseCase(repository: DrinkLogRepositoryKey.liveValue)
    static let previewValue = ObserveDrinkLogDayUseCase(repository: DrinkLogRepositoryKey.previewValue)
    static let testValue = ObserveDrinkLogDayUseCase(repository: DrinkLogRepositoryKey.testValue)
}

private enum ObserveDrinkLogWeekUseCaseKey: DependencyKey {
    static let liveValue = ObserveDrinkLogWeekUseCase(repository: DrinkLogRepositoryKey.liveValue)
    static let previewValue = ObserveDrinkLogWeekUseCase(repository: DrinkLogRepositoryKey.previewValue)
    static let testValue = ObserveDrinkLogWeekUseCase(repository: DrinkLogRepositoryKey.testValue)
}

private enum DeleteDrinkUseCaseKey: DependencyKey {
    static let liveValue = DeleteDrinkUseCase(drinkLog: DrinkLogRepositoryKey.liveValue)
    static let previewValue = DeleteDrinkUseCase(drinkLog: DrinkLogRepositoryKey.previewValue)
    static let testValue = DeleteDrinkUseCase(drinkLog: DrinkLogRepositoryKey.testValue)
}

private enum AddDemoHistoryUseCaseKey: DependencyKey {
    static let liveValue = AddDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.liveValue)
    static let previewValue = AddDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.previewValue)
    static let testValue = AddDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.testValue)
}

private enum RemoveDemoHistoryUseCaseKey: DependencyKey {
    static let liveValue = RemoveDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.liveValue)
    static let previewValue = RemoveDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.previewValue)
    static let testValue = RemoveDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.testValue)
}

private enum ObserveDemoHistoryUseCaseKey: DependencyKey {
    static let liveValue = ObserveDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.liveValue)
    static let previewValue = ObserveDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.previewValue)
    static let testValue = ObserveDemoHistoryUseCase(drinkLog: DrinkLogRepositoryKey.testValue)
}

/// The error an unimplemented dependency throws after reporting its issue.
private struct UnimplementedDependency: Error {}

/// The drink log repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedDrinkLogRepository: DrinkLogRepository {
    func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        reportIssue("A test observed the drink log without overriding \\.drinkLogRepository or \\.observeLoggedDrinks.")
        return AsyncStream { $0.finish() }
    }

    func intakeToday(in calendar: Calendar) -> AsyncStream<DailyCaffeineIntake> {
        reportIssue(
            "A test observed today's intake without overriding \\.drinkLogRepository or \\.observeCaffeineIntakeToday."
        )
        return AsyncStream { $0.finish() }
    }

    func log(_ drink: LoggedDrink) async throws {
        reportIssue("A test logged a drink without overriding \\.drinkLogRepository or \\.logDrink.")
        throw UnimplementedDependency()
    }

    func day(containing date: Date, in calendar: Calendar) -> AsyncStream<DrinkLogDay> {
        reportIssue("A test observed a day of the drink log without overriding \\.drinkLogRepository.")
        return AsyncStream { $0.finish() }
    }

    func recentDays(_ count: Int, in calendar: Calendar) -> AsyncStream<[DrinkLogDay]> {
        reportIssue(
            "A test observed the recent days without overriding \\.drinkLogRepository or \\.observeDrinkLogWeek.")
        return AsyncStream { $0.finish() }
    }

    func delete(_ id: LoggedDrink.ID) async throws {
        reportIssue("A test deleted a drink without overriding \\.drinkLogRepository.")
        throw UnimplementedDependency()
    }

    func hasDemoHistory() -> AsyncStream<Bool> {
        reportIssue(
            "A test observed the demo history without overriding \\.drinkLogRepository or \\.observeDemoHistory.")
        return AsyncStream { $0.finish() }
    }

    func addDemoHistory(in calendar: Calendar) async throws {
        reportIssue("A test added the demo history without overriding \\.drinkLogRepository or \\.addDemoHistory.")
        throw UnimplementedDependency()
    }

    func removeDemoHistory() async throws {
        reportIssue(
            "A test removed the demo history without overriding \\.drinkLogRepository or \\.removeDemoHistory.")
        throw UnimplementedDependency()
    }
}
