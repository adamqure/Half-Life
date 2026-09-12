//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SwiftDataDrinkLogDataSource
//

import Foundation
import OSLog
import SwiftData

/// The drink log's storage: a SwiftData store that syncs to the user's private CloudKit database.
///
/// It's a model actor, so it runs off the main actor (constitution Article IV.1). It keeps one change stream per
/// subscriber, and signals each one after every successful store and deletion. The Drink Composer article lists its
/// requirements, SRC-1 to SRC-7, and the Caffeine Decay Model article lists DATA-1 to DATA-5.
@ModelActor
actor SwiftDataDrinkLogDataSource: DrinkLogDataSource {
    private static let logger = Logger(for: SwiftDataDrinkLogDataSource.self)

    private var subscribers: [UUID: AsyncStream<Void>.Continuation] = [:]

    /// Creates the drink log's model container.
    ///
    /// The app's store syncs through CloudKit with `.automatic`, which uses the first iCloud container in the app's
    /// entitlements, and stays local while there's none. An in-memory store never syncs, so tests and previews
    /// never touch iCloud.
    ///
    /// - Parameter isStoredInMemoryOnly: Whether the store lives only in memory.
    /// - Returns: A container for ``DrinkRecord``.
    /// - Throws: An error if the store couldn't be opened.
    static func makeModelContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: Schema([DrinkRecord.self]),
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: isStoredInMemoryOnly ? .none : .automatic)
        return try ModelContainer(for: DrinkRecord.self, configurations: configuration)
    }

    /// Stores `drink`, unmarked, then signals a change to every subscriber.
    ///
    /// - Parameter drink: The drink to store.
    /// - Throws: The store's error if the drink couldn't be saved. Nothing is signalled then.
    func store(_ drink: LoggedDrink) async throws {
        modelContext.insert(DrinkRecord(drink))
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            Self.logFailure("store a drink", error)
            throw error
        }
        for subscriber in subscribers.values {
            subscriber.yield()
        }
    }

    /// Deletes the drink with identifier `id`, marked or not, then signals a change to every subscriber. When no
    /// stored drink has that identifier, it changes nothing and signals nothing.
    ///
    /// - Parameter id: The identifier of the drink to delete.
    /// - Throws: The store's error if the deletion couldn't be saved. Nothing is signalled then.
    func delete(_ id: LoggedDrink.ID) async throws {
        do {
            let records = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<DrinkRecord> { $0.id == id }))
            guard !records.isEmpty else { return }
            for record in records {
                modelContext.delete(record)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            Self.logFailure("delete a drink", error)
            throw error
        }
        for subscriber in subscribers.values {
            subscriber.yield()
        }
    }

    /// Returns every stored drink, oldest first, whether or not it's marked negligible.
    ///
    /// - Throws: The store's error if the drinks couldn't be read.
    func drinks() async throws -> [LoggedDrink] {
        try loggedDrinks(matching: FetchDescriptor(sortBy: [SortDescriptor(\DrinkRecord.consumedAt)]))
    }

    /// Returns the drinks that aren't marked negligible, oldest first.
    ///
    /// - Throws: The store's error if the drinks couldn't be read.
    func nonNegligibleDrinks() async throws -> [LoggedDrink] {
        try loggedDrinks(
            matching: FetchDescriptor(
                predicate: #Predicate<DrinkRecord> { $0.isNegligible == false },
                sortBy: [SortDescriptor(\DrinkRecord.consumedAt)]))
    }

    /// Marks the drinks with the given intakes' identifiers as negligible. It signals nothing.
    ///
    /// - Parameter intakes: The intakes whose drinks to mark.
    /// - Throws: The store's error if the marks couldn't be saved.
    func markNegligible(_ intakes: [CaffeineIntake]) async throws {
        let ids = intakes.map(\.id)
        guard !ids.isEmpty else { return }
        do {
            let records = try modelContext.fetch(
                FetchDescriptor(predicate: #Predicate<DrinkRecord> { ids.contains($0.id) }))
            for record in records {
                record.isNegligible = true
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            Self.logFailure("mark drinks negligible", error)
            throw error
        }
    }

    /// Returns a stream for one subscriber that yields after each store and each deletion. It ends when its
    /// subscriber stops listening.
    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        return stream
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Fetches records and maps them to drinks. A record whose type this version doesn't know, such as one synced
    /// from a newer version, is skipped rather than failing the whole read.
    private func loggedDrinks(matching descriptor: FetchDescriptor<DrinkRecord>) throws -> [LoggedDrink] {
        let records: [DrinkRecord]
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            Self.logFailure("read drinks", error)
            throw error
        }
        let drinks = records.compactMap(\.loggedDrink)
        if drinks.count < records.count {
            Self.logger.error("Skipped a stored drink whose type this version doesn't recognize.")
        }
        return drinks
    }

    /// Logs a failed operation with the error's domain and code, and no values (constitution Article XI.6).
    private static func logFailure(_ operation: String, _ error: any Error) {
        let domain = (error as NSError).domain
        let code = (error as NSError).code
        logger.error("Couldn't \(operation, privacy: .public): \(domain, privacy: .public) \(code, privacy: .public)")
    }
}
