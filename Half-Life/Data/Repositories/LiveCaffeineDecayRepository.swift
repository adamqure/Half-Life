//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveCaffeineDecayRepository
//

import Foundation
import OSLog

/// The live caffeine decay repository: the source of truth for the active curve and the caffeine status.
///
/// It reads the drinks that aren't marked negligible from its ``DrinkLogDataSource``, the half-life from its
/// ``HalfLifeDataSource``, the absorption rate from its ``AbsorptionRateDataSource``, the bedtime from its
/// ``BedtimeDataSource``, and the current time from its ``ClockDataSource``. It combines the half-life and the
/// absorption rate into a ``CaffeineKinetics``, and executes ``CaffeineDecayRule`` for the curve and
/// ``CaffeineStatusRule`` for the status.
///
/// It recalculates the curve when a subscriber arrives and when the drink log signals a change, never on a timer.
/// It recalculates the status on the same events, and also at every whole minute once anyone observes the status,
/// because the status is about the current time. It's an actor, off the main actor (constitution Article I.13). The
/// Caffeine Decay Model article lists its requirements, REPO-1 to REPO-10.
actor LiveCaffeineDecayRepository: CaffeineDecayRepository {
    private static let logger = Logger(for: LiveCaffeineDecayRepository.self)

    /// A status subscriber: its stream, and the calendar its bedtime is a time of day in.
    private struct StatusSubscriber {
        let calendar: Calendar
        let continuation: AsyncStream<CaffeineStatus>.Continuation
    }

    /// What a status is calculated from, read once for every subscriber.
    private struct StatusInputs {
        let intakes: [CaffeineIntake]
        let kinetics: CaffeineKinetics
        let bedtime: Bedtime
    }

    private let drinkLog: any DrinkLogDataSource
    private let halfLifeSource: any HalfLifeDataSource
    private let absorptionSource: any AbsorptionRateDataSource
    private let bedtimeSource: any BedtimeDataSource
    private let clock: any ClockDataSource
    private let rule = CaffeineDecayRule()
    private let statusRule = CaffeineStatusRule()
    private var subscribers: [UUID: AsyncStream<[CaffeineLevel]>.Continuation] = [:]
    private var statusSubscribers: [UUID: StatusSubscriber] = [:]
    private var isListening = false
    private var changeListener: Task<Void, Never>?
    private var minuteListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - drinkLog: The drink log the intakes come from, shared with the drink log repository.
    ///   - halfLife: Where the user's half-life is read from.
    ///   - absorption: Where the absorption rate is read from.
    ///   - bedtime: Where the user's bedtime is read from.
    ///   - clock: The current time, and the minutes the status follows.
    init(
        drinkLog: any DrinkLogDataSource, halfLife: any HalfLifeDataSource, absorption: any AbsorptionRateDataSource,
        bedtime: any BedtimeDataSource, clock: any ClockDataSource
    ) {
        self.drinkLog = drinkLog
        halfLifeSource = halfLife
        absorptionSource = absorption
        bedtimeSource = bedtime
        self.clock = clock
    }

    deinit {
        changeListener?.cancel()
        minuteListener?.cancel()
    }

    /// Streams the active curve.
    ///
    /// A new subscriber immediately receives a curve calculated for the current time. After that, every subscriber
    /// receives a new curve whenever the drink log signals a change.
    nonisolated func curve() -> AsyncStream<[CaffeineLevel]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [CaffeineLevel].self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Streams the caffeine status.
    ///
    /// A new subscriber immediately receives a status for the current time. After that, every status subscriber
    /// receives a new status at every minute the clock streams, and whenever the drink log signals a change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    nonisolated func status(in calendar: Calendar) -> AsyncStream<CaffeineStatus> {
        let (stream, continuation) = AsyncStream.makeStream(of: CaffeineStatus.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeStatusSubscriber(id) }
        }
        Task { await addStatusSubscriber(id, StatusSubscriber(calendar: calendar, continuation: continuation)) }
        return stream
    }

    /// Starts listening to the drink log before the first curve goes out, so no change after it is missed.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[CaffeineLevel]>.Continuation) async {
        await listenForChanges()
        subscribers[id] = continuation
        if let curve = await calculateCurve() {
            continuation.yield(curve)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Starts listening to the drink log before the first status goes out, and follows the clock's minutes after it,
    /// so the first status is always the one for the current time.
    private func addStatusSubscriber(_ id: UUID, _ subscriber: StatusSubscriber) async {
        await listenForChanges()
        statusSubscribers[id] = subscriber
        await publishStatus(at: clock.now(), to: [subscriber])
        listenForMinutes()
    }

    private func removeStatusSubscriber(_ id: UUID) {
        statusSubscribers[id] = nil
    }

    /// Subscribes to the drink log's changes once, for the life of the repository.
    private func listenForChanges() async {
        guard !isListening else { return }
        isListening = true
        let changes = await drinkLog.changes()
        changeListener = Task { [weak self] in
            for await _ in changes {
                await self?.publishChange()
            }
        }
    }

    /// Follows the clock's minutes once, from the first status subscriber on. Only the status follows them.
    private func listenForMinutes() {
        guard minuteListener == nil else { return }
        let minutes = clock.minutes()
        minuteListener = Task { [weak self] in
            for await minute in minutes {
                await self?.publishStatusToEverySubscriber(at: minute)
            }
        }
    }

    /// Publishes a recalculated curve and status to every subscriber, after the drink log changes.
    private func publishChange() async {
        if !subscribers.isEmpty, let curve = await calculateCurve() {
            for subscriber in subscribers.values {
                subscriber.yield(curve)
            }
        }
        await publishStatusToEverySubscriber(at: clock.now())
    }

    private func publishStatusToEverySubscriber(at now: Date) async {
        await publishStatus(at: now, to: Array(statusSubscribers.values))
    }

    /// Calculates the status at `now` for each of `subscribers`, in its own calendar, and publishes it.
    private func publishStatus(at now: Date, to subscribers: [StatusSubscriber]) async {
        guard !subscribers.isEmpty, let inputs = await readStatusInputs() else { return }
        for subscriber in subscribers {
            let status = statusRule.status(
                from: inputs.intakes, kinetics: inputs.kinetics, bedtime: inputs.bedtime, now: now,
                calendar: subscriber.calendar)
            subscriber.continuation.yield(status)
        }
    }

    /// Reads the drinks that still count, the half-life, the absorption rate, and the bedtime. Returns `nil`, after
    /// logging, if any of them couldn't be read.
    private func readStatusInputs() async -> StatusInputs? {
        do {
            return StatusInputs(
                intakes: try await drinkLog.nonNegligibleDrinks().map(\.intake),
                kinetics: try await readKinetics(),
                bedtime: try await bedtimeSource.bedtime())
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error("Couldn't calculate the status: \(domain, privacy: .public) \(code, privacy: .public)")
            return nil
        }
    }

    /// Calculates the curve for the current time, and marks the intakes that no longer count. Returns `nil`, after
    /// logging, if the drinks, the half-life, or the absorption rate couldn't be read.
    private func calculateCurve() async -> [CaffeineLevel]? {
        do {
            let intakes = try await drinkLog.nonNegligibleDrinks().map(\.intake)
            let kinetics = try await readKinetics()
            let now = clock.now()
            await markNegligible(rule.negligibleIntakes(from: intakes, kinetics: kinetics, now: now))
            return rule.curve(from: intakes, kinetics: kinetics, now: now)
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error("Couldn't calculate the curve: \(domain, privacy: .public) \(code, privacy: .public)")
            return nil
        }
    }

    /// Reads the half-life and the absorption rate from their data sources.
    private func readKinetics() async throws -> CaffeineKinetics {
        CaffeineKinetics(
            halfLife: try await halfLifeSource.halfLife(), absorption: try await absorptionSource.absorptionRate())
    }

    /// Has the drink log mark `intakes`. A failure is logged and otherwise ignored: marking only saves work, so the
    /// curve is the same either way (REPO-4).
    private func markNegligible(_ intakes: [CaffeineIntake]) async {
        guard !intakes.isEmpty else { return }
        do {
            try await drinkLog.markNegligible(intakes)
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't mark negligible intakes: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
        }
    }
}
