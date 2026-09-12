//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveDrinkLogRepository
//

import Foundation
import OSLog

/// The live drink log repository: the source of truth for every drink the user has logged.
///
/// It stores drinks through its ``DrinkLogDataSource``, which it shares with ``LiveCaffeineDecayRepository``. Before
/// storing, it executes ``DrinkLogRule`` with the current time from its ``ClockDataSource``. It publishes what the
/// data source holds: a new subscriber gets every drink, and every subscriber gets the updated set after each change
/// the data source signals. It's an actor, off the main actor (constitution Article I.13). The Drink Composer
/// article lists its requirements, DLOG-1 to DLOG-4.
actor LiveDrinkLogRepository: DrinkLogRepository {
    private static let logger = Logger(for: LiveDrinkLogRepository.self)

    private let dataSource: any DrinkLogDataSource
    private let clock: any ClockDataSource
    private let rule = DrinkLogRule()
    private var subscribers: [UUID: AsyncStream<[LoggedDrink]>.Continuation] = [:]
    private var isListening = false
    private var changeListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - dataSource: Where drinks are stored, shared with the caffeine decay repository.
    ///   - clock: The current time, for ``DrinkLogRule``.
    init(dataSource: any DrinkLogDataSource, clock: any ClockDataSource) {
        self.dataSource = dataSource
        self.clock = clock
    }

    deinit {
        changeListener?.cancel()
    }

    /// Streams every logged drink, oldest first.
    ///
    /// A new subscriber immediately receives every drink. After that, every subscriber receives the updated set
    /// whenever the data source signals a change.
    nonisolated func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [LoggedDrink].self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Checks `drink` with ``DrinkLogRule``, then stores it. Subscribers get the updated set when the data source
    /// signals the change.
    ///
    /// - Parameter drink: The drink to store.
    /// - Throws: A ``DrinkLogRule/Violation`` if the drink can't be logged, or the data source's error if it couldn't
    ///   be stored. Nothing is stored or published then.
    func log(_ drink: LoggedDrink) async throws {
        try rule.validate(drink, now: clock.now())
        try await dataSource.store(drink)
    }

    /// Starts listening to the data source before the first set goes out, so no change after it is missed.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[LoggedDrink]>.Continuation) async {
        await listenForChanges()
        subscribers[id] = continuation
        if let drinks = await readDrinks() {
            continuation.yield(drinks)
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
        guard !subscribers.isEmpty, let drinks = await readDrinks() else { return }
        for subscriber in subscribers.values {
            subscriber.yield(drinks)
        }
    }

    /// Reads every drink. Returns `nil`, after logging the error without any drink data, if they couldn't be read.
    private func readDrinks() async -> [LoggedDrink]? {
        do {
            return try await dataSource.drinks()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the drink log: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
    }
}
