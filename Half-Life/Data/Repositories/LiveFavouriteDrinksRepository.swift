//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveFavouriteDrinksRepository
//

import Foundation
import OSLog

/// The live favourites repository: the source of truth for the one-tap favourites.
///
/// It reads every logged drink from its ``DrinkLogDataSource``, which it shares with ``LiveDrinkLogRepository`` and
/// ``LiveCaffeineDecayRepository``, and executes ``FavouriteDrinksRule`` on them. A new subscriber gets the current
/// favourites, and every subscriber gets them again after each change the data source signals. It's an actor, off the
/// main actor (constitution Article I.13). The One-Tap Log article lists its requirements, FAVREPO-1 to FAVREPO-3.
actor LiveFavouriteDrinksRepository: FavouriteDrinksRepository {
    private static let logger = Logger(for: LiveFavouriteDrinksRepository.self)

    private let dataSource: any DrinkLogDataSource
    private let rule = FavouriteDrinksRule()
    private var subscribers: [UUID: AsyncStream<[FavouriteDrink]>.Continuation] = [:]
    private var isListening = false
    private var changeListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameter dataSource: Where drinks are stored, shared with the other repositories that read drinks.
    init(dataSource: any DrinkLogDataSource) {
        self.dataSource = dataSource
    }

    deinit {
        changeListener?.cancel()
    }

    /// Streams the favourites, most logged first.
    ///
    /// A new subscriber immediately receives the current favourites. After that, every subscriber receives them again
    /// whenever the data source signals a change.
    nonisolated func favourites() -> AsyncStream<[FavouriteDrink]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [FavouriteDrink].self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Starts listening to the data source before the first favourites go out, so no change after them is missed.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[FavouriteDrink]>.Continuation) async {
        await listenForChanges()
        subscribers[id] = continuation
        if let favourites = await readFavourites() {
            continuation.yield(favourites)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Subscribes to the data source's changes once, for the life of the repository.
    private func listenForChanges() async {
        guard !isListening else { return }
        isListening = true
        let changes = await dataSource.changes()
        changeListener = Task { [weak self] in
            for await _ in changes {
                await self?.publishToEverySubscriber()
            }
        }
    }

    private func publishToEverySubscriber() async {
        guard !subscribers.isEmpty, let favourites = await readFavourites() else { return }
        for subscriber in subscribers.values {
            subscriber.yield(favourites)
        }
    }

    /// Reads every drink and finds the favourites. Returns `nil`, after logging the error without any drink data, if
    /// the drinks couldn't be read.
    private func readFavourites() async -> [FavouriteDrink]? {
        do {
            return rule.favourites(from: try await dataSource.drinks())
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the drink log: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
    }
}
