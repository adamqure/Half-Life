//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogDataSourceDependencies
//

import ComposableArchitecture
import Foundation
import OSLog
import SwiftData

/// Registers the app's one drink log data source, which every repository that reads or writes drinks shares.
///
/// Repositories share a data source so that a write through one reaches the others (see the Architecture article).
/// Each repository key builds its values from this key's values. There's no `DependencyValues` property, because
/// only repositories use data sources.
enum DrinkLogDataSourceKey: DependencyKey {
    /// The app's store, on the device only. If the store can't be opened, this launch uses an empty in-memory store
    /// instead, and the failure is logged. Under a UI test, it's always an empty in-memory store
    /// (``UITestLaunchConfiguration``).
    static let liveValue: any DrinkLogDataSource = makeLiveValue(configuration: .current)

    /// An empty in-memory store, so previews never touch the device's store.
    static let previewValue: any DrinkLogDataSource = makeDataSource {
        try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: true)
    }

    /// A data source that reports an issue when a test uses it.
    static let testValue: any DrinkLogDataSource = UnimplementedDrinkLogDataSource()

    private static let logger = Logger(for: DrinkLogDataSourceKey.self)

    /// The live data source for a launch with `configuration`.
    ///
    /// A UI test gets an empty store that lives only in memory, so every UI test starts from the same log, and none
    /// writes to the simulator's own drinks. A test that needs a drink logs it.
    ///
    /// - Parameter configuration: How a UI test asked the app to start, if one did.
    /// - Returns: The device's store outside UI tests, or an empty in-memory store under one.
    static func makeLiveValue(configuration: UITestLaunchConfiguration) -> SwiftDataDrinkLogDataSource {
        makeDataSource {
            try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: configuration.isUITest)
        }
    }

    /// Creates a data source over the store that `openStore` opens, or over an empty in-memory store if it throws.
    ///
    /// - Parameter openStore: Opens the store's model container.
    /// - Returns: The data source.
    static func makeDataSource(opening openStore: () throws -> ModelContainer) -> SwiftDataDrinkLogDataSource {
        do {
            return SwiftDataDrinkLogDataSource(modelContainer: try openStore())
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            logger.error("The drink log store didn't open: \(domain, privacy: .public) \(code, privacy: .public)")
            return SwiftDataDrinkLogDataSource(modelContainer: inMemoryContainer())
        }
    }

    /// An empty in-memory container. Opening one fails only if the model itself is invalid, which is a bug in the
    /// app rather than a condition it can recover from.
    private static func inMemoryContainer() -> ModelContainer {
        do {
            return try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: true)
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            logger.fault("Drink log model won't open in memory: \(domain, privacy: .public) \(code, privacy: .public)")
            fatalError("The drink log model can't open an in-memory store.")
        }
    }
}

/// The error an unimplemented data source throws after reporting its issue.
private struct UnimplementedDataSource: Error {}

/// The drink log data source in tests that reach it without overriding a repository. Using it reports an issue.
private struct UnimplementedDrinkLogDataSource: DrinkLogDataSource {
    func store(_ drink: LoggedDrink) async throws {
        throw unimplemented("stored a drink")
    }

    func delete(_ id: LoggedDrink.ID) async throws {
        throw unimplemented("deleted a drink")
    }

    func replaceDemoDrinks(with drinks: [LoggedDrink]) async throws {
        throw unimplemented("replaced the demo drinks")
    }

    func drinks() async throws -> [LoggedDrink] {
        throw unimplemented("read the drinks")
    }

    func nonNegligibleDrinks() async throws -> [LoggedDrink] {
        throw unimplemented("read the drinks that still count")
    }

    func markNegligible(_ intakes: [CaffeineIntake]) async throws {
        throw unimplemented("marked intakes negligible")
    }

    func changes() async -> AsyncStream<Void> {
        _ = unimplemented("observed the drink log's changes")
        return AsyncStream { $0.finish() }
    }

    private func unimplemented(_ action: String) -> UnimplementedDataSource {
        reportIssue("A test \(action) through the drink log data source without overriding a repository.")
        return UnimplementedDataSource()
    }
}
