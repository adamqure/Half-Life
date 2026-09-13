//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveWidgetSnapshotRepository
//

import Foundation
import OSLog

/// The live widget snapshot repository: the source of truth for what the Home Screen widgets show.
///
/// It reads the drinks from its ``DrinkLogDataSource``, the bedtime and onboarding from its ``UserProfileDataSource``,
/// and the half-life from its ``HalfLifeDataSource``, each shared with the repositories that read them too, and
/// executes ``WidgetSnapshotRule``. After each change any of them signals, it stores the new snapshot through its
/// ``WidgetSnapshotDataSource``, then asks its ``WidgetReloadDataSource`` to reload the widgets. It's an actor, off the
/// main actor (constitution Article I.13). The Widgets article lists its requirements, WSREPO-1 to WSREPO-3.
actor LiveWidgetSnapshotRepository: WidgetSnapshotRepository {
    private static let logger = Logger(for: LiveWidgetSnapshotRepository.self)

    private let drinkLog: any DrinkLogDataSource
    private let profileSource: any UserProfileDataSource
    private let halfLifeSource: any HalfLifeDataSource
    private let absorptionSource: any AbsorptionRateDataSource
    private let clock: any ClockDataSource
    private let snapshotStore: any WidgetSnapshotDataSource
    private let widgets: any WidgetReloadDataSource
    private let rule = WidgetSnapshotRule()
    private var subscribers: [UUID: AsyncStream<WidgetSnapshot>.Continuation] = [:]
    private var isListening = false
    private var changeListeners: [Task<Void, Never>] = []

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - drinkLog: Where drinks are stored, shared with the other repositories that read drinks.
    ///   - profile: Where the profile is stored, for the bedtime and whether onboarding is complete.
    ///   - halfLife: Where the user's half-life is read from.
    ///   - absorption: Where the absorption rate is read from.
    ///   - clock: The current time.
    ///   - snapshots: Where the snapshot is stored for the widget extension.
    ///   - widgets: What reloads the widgets once a new snapshot is stored.
    init(
        drinkLog: any DrinkLogDataSource, profile: any UserProfileDataSource, halfLife: any HalfLifeDataSource,
        absorption: any AbsorptionRateDataSource, clock: any ClockDataSource, snapshots: any WidgetSnapshotDataSource,
        widgets: any WidgetReloadDataSource
    ) {
        self.drinkLog = drinkLog
        profileSource = profile
        halfLifeSource = halfLife
        absorptionSource = absorption
        self.clock = clock
        snapshotStore = snapshots
        self.widgets = widgets
    }

    deinit {
        for listener in changeListeners {
            listener.cancel()
        }
    }

    /// Streams the snapshot.
    ///
    /// A new subscriber immediately receives a snapshot calculated for the current data, which is stored and reloads
    /// the widgets. After that, every subscriber receives a new one whenever the drink log, the profile, or the
    /// half-life changes.
    nonisolated func snapshots() -> AsyncStream<WidgetSnapshot> {
        let (stream, continuation) = AsyncStream.makeStream(of: WidgetSnapshot.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Starts listening to the data sources before the first snapshot goes out, so no change after it is missed.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<WidgetSnapshot>.Continuation) async {
        await listenForChanges()
        subscribers[id] = continuation
        if let snapshot = await refresh() {
            continuation.yield(snapshot)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Subscribes to the data sources' changes once, for the life of the repository.
    private func listenForChanges() async {
        guard !isListening else { return }
        isListening = true
        let streams = [await drinkLog.changes(), await profileSource.changes(), await halfLifeSource.changes()]
        for changes in streams {
            changeListeners.append(
                Task { [weak self] in
                    for await _ in changes {
                        await self?.publishToEverySubscriber()
                    }
                })
        }
    }

    private func publishToEverySubscriber() async {
        guard !subscribers.isEmpty, let snapshot = await refresh() else { return }
        for subscriber in subscribers.values {
            subscriber.yield(snapshot)
        }
    }

    /// Calculates the snapshot, stores it, and then reloads the widgets. Returns `nil`, after logging the error without
    /// any of its data, if the data couldn't be read or the snapshot couldn't be stored.
    private func refresh() async -> WidgetSnapshot? {
        let snapshot: WidgetSnapshot
        do {
            let profile = try await profileSource.storedProfile()
            let kinetics = CaffeineKinetics(
                halfLife: try await halfLifeSource.halfLife(), absorption: try await absorptionSource.absorptionRate())
            snapshot = rule.snapshot(
                drinks: try await drinkLog.drinks(), intakes: try await drinkLog.nonNegligibleDrinks().map(\.intake),
                kinetics: kinetics, profile: profile, now: clock.now())
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the widgets' data: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
        do {
            try await snapshotStore.store(snapshot)
        } catch {
            return nil
        }
        widgets.reloadAllTimelines()
        return snapshot
    }
}
