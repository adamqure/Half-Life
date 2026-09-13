//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeDrinkLogDataSource
//

import Foundation

@testable import Half_Life

/// An in-memory drink log data source for repository tests.
///
/// It holds drinks and their negligible marks, and records what repositories ask of it. Like the live data source,
/// `store(_:)` signals a change and `markNegligible(_:)` doesn't. A test can also insert a drink without a signal,
/// then call `signalChange()` to control exactly when repositories hear about it.
actor FakeDrinkLogDataSource: DrinkLogDataSource {
    /// Every drink held, in the order it was added.
    private(set) var heldDrinks: [LoggedDrink]
    /// The identifiers of the drinks marked negligible.
    private(set) var negligibleIDs: Set<UUID>
    /// The intakes passed to each `markNegligible(_:)` call, in order.
    private(set) var markedIntakes: [[CaffeineIntake]] = []
    /// How many times `drinks()` was called.
    private(set) var drinksCallCount = 0
    /// How many times `nonNegligibleDrinks()` was called.
    private(set) var nonNegligibleDrinksCallCount = 0
    /// The error `store(_:)` throws instead of storing, if any.
    private let storeError: (any Error)?
    /// The error `drinks()` and `nonNegligibleDrinks()` throw, if any. Set it with `failReads(with:)`.
    private var readError: (any Error)?
    /// The error `markNegligible(_:)` throws instead of marking, if any. Set it with `failMarks(with:)`.
    private var markError: (any Error)?
    /// The error `delete(_:)` throws instead of deleting, if any. Set it with `failDeletes(with:)`.
    private var deleteError: (any Error)?
    /// The error `replaceDemoDrinks(with:)` throws instead of replacing, if any. Set it with
    /// `failDemoReplacements(with:)`.
    private var demoReplacementError: (any Error)?
    private var subscribers: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(drinks: [LoggedDrink] = [], negligibleIDs: Set<UUID> = [], storeError: (any Error)? = nil) {
        heldDrinks = drinks
        self.negligibleIDs = negligibleIDs
        self.storeError = storeError
    }

    /// The number of streams from `changes()` still being listened to.
    var subscriberCount: Int {
        subscribers.count
    }

    func store(_ drink: LoggedDrink) async throws {
        if let storeError {
            throw storeError
        }
        heldDrinks.append(drink)
        signalChange()
    }

    /// Like the live data source, it signals a change only when it held a drink with the identifier.
    func delete(_ id: LoggedDrink.ID) async throws {
        if let deleteError {
            throw deleteError
        }
        guard heldDrinks.contains(where: { $0.id == id }) else { return }
        heldDrinks.removeAll { $0.id == id }
        signalChange()
    }

    /// Like the live data source, it stores each new drink marked demo, and signals a change only when something
    /// changed.
    func replaceDemoDrinks(with drinks: [LoggedDrink]) async throws {
        if let demoReplacementError {
            throw demoReplacementError
        }
        let hadDemoDrinks = heldDrinks.contains(where: \.isDemo)
        heldDrinks.removeAll(where: \.isDemo)
        heldDrinks += drinks.map {
            LoggedDrink(
                id: $0.id, type: $0.type, quantity: $0.quantity, milligrams: $0.milligrams, consumedAt: $0.consumedAt,
                isDemo: true)
        }
        if hadDemoDrinks || !drinks.isEmpty {
            signalChange()
        }
    }

    func drinks() async throws -> [LoggedDrink] {
        drinksCallCount += 1
        if let readError {
            throw readError
        }
        return oldestFirst(heldDrinks)
    }

    func nonNegligibleDrinks() async throws -> [LoggedDrink] {
        nonNegligibleDrinksCallCount += 1
        if let readError {
            throw readError
        }
        return oldestFirst(heldDrinks.filter { !negligibleIDs.contains($0.id) })
    }

    func markNegligible(_ intakes: [CaffeineIntake]) async throws {
        if let markError {
            throw markError
        }
        markedIntakes.append(intakes)
        negligibleIDs.formUnion(intakes.map(\.id))
    }

    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        return stream
    }

    /// Makes every read throw `error` from now on, or read normally again when it's `nil`.
    func failReads(with error: (any Error)?) {
        readError = error
    }

    /// Makes every mark throw `error` from now on, or mark normally again when it's `nil`.
    func failMarks(with error: (any Error)?) {
        markError = error
    }

    /// Makes every deletion throw `error` from now on, or delete normally again when it's `nil`.
    func failDeletes(with error: (any Error)?) {
        deleteError = error
    }

    /// Makes every demo replacement throw `error` from now on, or replace normally again when it's `nil`.
    func failDemoReplacements(with error: (any Error)?) {
        demoReplacementError = error
    }

    /// Adds a drink without signalling a change.
    func insert(_ drink: LoggedDrink) {
        heldDrinks.append(drink)
    }

    /// Signals a change to every subscriber, as the live data source does after a store.
    func signalChange() {
        for subscriber in subscribers.values {
            subscriber.yield()
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    private func oldestFirst(_ drinks: [LoggedDrink]) -> [LoggedDrink] {
        drinks.sorted { $0.consumedAt < $1.consumedAt }
    }
}
