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
///
/// It also derives four values from the cutoff's inputs, which add the threshold from its
/// ``SleepThresholdDataSource`` and the usual drink ``FavouriteDrinksRule`` finds: the cutoff, the next nights'
/// cutoffs, and the composer's warning, from ``CaffeineCutoffRule``, and tonight's sleep window, from
/// ``SleepWindowRule``. It reads the inputs once for all of them, on the status's events, and sends a subscriber a
/// value only when it changed. See CUTREPO-1 to 5 and WARNREPO-1 to 3 (Caffeine Cutoff), and SWREPO-1 to 4 (Insights).
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

    /// A subscriber to a value derived from the cutoff's inputs: the cutoff, the upcoming cutoffs, the composer's
    /// warning, or the sleep window.
    private struct DerivedSubscriber {
        /// Calculates the value at a time, and sends it unless it's the last value sent. Returns the value it sent, or
        /// `nil` when it sent nothing.
        let publish: @Sendable (CaffeineCutoffRule.Inputs, Date, (any Sendable)?) -> (any Sendable)?
        /// The last value sent, or `nil` before the first.
        var lastSent: (any Sendable)?
    }

    private let drinkLog: any DrinkLogDataSource
    private let halfLifeSource: any HalfLifeDataSource
    private let absorptionSource: any AbsorptionRateDataSource
    private let bedtimeSource: any BedtimeDataSource
    private let clock: any ClockDataSource
    private let thresholdSource: any SleepThresholdDataSource
    private let rule = CaffeineDecayRule()
    private let statusRule = CaffeineStatusRule()
    private let cutoffRule = CaffeineCutoffRule()
    private let favouritesRule = FavouriteDrinksRule()
    private let sleepWindowRule = SleepWindowRule()
    private var subscribers: [UUID: AsyncStream<[CaffeineLevel]>.Continuation] = [:]
    private var statusSubscribers: [UUID: StatusSubscriber] = [:]
    private var derivedSubscribers: [UUID: DerivedSubscriber] = [:]
    private var isListening = false
    private var changeListeners: [Task<Void, Never>] = []
    private var minuteListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - drinkLog: The drink log the intakes come from, shared with the drink log repository.
    ///   - halfLife: Where the user's half-life is read from.
    ///   - absorption: Where the absorption rate is read from.
    ///   - bedtime: Where the user's bedtime is read from.
    ///   - clock: The current time, and the minutes the status and the derived values follow.
    ///   - threshold: Where the sleep threshold is read from: the caffeine tolerance, or the standard one by default.
    init(
        drinkLog: any DrinkLogDataSource, halfLife: any HalfLifeDataSource, absorption: any AbsorptionRateDataSource,
        bedtime: any BedtimeDataSource, clock: any ClockDataSource,
        threshold: any SleepThresholdDataSource = StandardSleepThresholdDataSource()
    ) {
        self.drinkLog = drinkLog
        halfLifeSource = halfLife
        absorptionSource = absorption
        bedtimeSource = bedtime
        self.clock = clock
        thresholdSource = threshold
    }

    deinit {
        for listener in changeListeners {
            listener.cancel()
        }
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

    /// Streams the cutoff.
    ///
    /// A new subscriber immediately receives the cutoff for the current time. After that, it receives a new cutoff
    /// when a change the drink log signals, or a minute the clock streams, changes it.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    nonisolated func cutoff(in calendar: Calendar) -> AsyncStream<CaffeineCutoff> {
        let rule = cutoffRule
        return derivedStream { inputs, now in rule.cutoff(inputs, now: now, calendar: calendar) }
    }

    /// Streams the cutoffs for the next `nights` bedtimes, tonight's first, on the same events as the cutoff.
    ///
    /// - Parameters:
    ///   - nights: How many bedtimes to calculate a cutoff for.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    nonisolated func upcomingCutoffs(nights: Int, in calendar: Calendar) -> AsyncStream<[CaffeineCutoff]> {
        let rule = cutoffRule
        return derivedStream { inputs, now in
            let cutoffs = rule.cutoffs(inputs, nights: nights, now: now, calendar: calendar)
            return cutoffs.isEmpty ? nil : cutoffs
        }
    }

    /// Streams the drink composer's warning for `drink` consumed `secondsAgo` before the current time, or `nil` when it
    /// fits, on the same events as the cutoff.
    ///
    /// - Parameters:
    ///   - drink: The drink and quantity the composer has chosen.
    ///   - secondsAgo: How long before the current time it was consumed.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    nonisolated func cutoffWarning(
        for drink: FavouriteDrink, secondsAgo: TimeInterval, in calendar: Calendar
    ) -> AsyncStream<CutoffWarning?> {
        let rule = cutoffRule
        return derivedStream { inputs, now -> CutoffWarning?? in
            let checked = CaffeineCutoffRule.Inputs(
                drink: drink, intakes: inputs.intakes, kinetics: inputs.kinetics, threshold: inputs.threshold,
                bedtime: inputs.bedtime)
            return .some(rule.warning(checked, consumedAt: now.addingTimeInterval(-secondsAgo), calendar: calendar))
        }
    }

    /// Streams tonight's sleep window, on the same events as the cutoff.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the night and the bedtime are in.
    nonisolated func sleepWindow(in calendar: Calendar) -> AsyncStream<SleepWindow> {
        let rule = sleepWindowRule
        return derivedStream { inputs, now in
            let window = SleepWindowRule.Inputs(
                intakes: inputs.intakes, kinetics: inputs.kinetics, threshold: inputs.threshold,
                bedtime: inputs.bedtime)
            return rule.window(window, now: now, calendar: calendar)
        }
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

    /// Subscribes once to the changes of the drink log, half-life, bedtime, and threshold (REPO-5, 11, 12, TOLDECAY-1).
    private func listenForChanges() async {
        guard !isListening else { return }
        isListening = true
        let streams = await [
            drinkLog.changes(), halfLifeSource.changes(), bedtimeSource.changes(), thresholdSource.changes(),
        ]
        changeListeners = streams.map { changes in
            Task { [weak self] in
                for await _ in changes {
                    await self?.publishChange()
                }
            }
        }
    }

    /// Follows the clock's minutes once, from the first status or derived subscriber on. Only they follow them.
    private func listenForMinutes() {
        guard minuteListener == nil else { return }
        let minutes = clock.minutes()
        minuteListener = Task { [weak self] in
            for await minute in minutes {
                await self?.publishStatusToEverySubscriber(at: minute)
                await self?.publishDerivedToEverySubscriber(at: minute)
            }
        }
    }

    /// Publishes a recalculated curve and status to every subscriber, and each derived value to the subscribers it
    /// changed for, after the drink log changes.
    private func publishChange() async {
        if !subscribers.isEmpty, let curve = await calculateCurve() {
            for subscriber in subscribers.values {
                subscriber.yield(curve)
            }
        }
        await publishStatusToEverySubscriber(at: clock.now())
        await publishDerivedToEverySubscriber(at: clock.now())
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

// The derived values, in an extension that keeps the actor's body short. In this file, it reaches private members.
extension LiveCaffeineDecayRepository {
    /// A stream of what `calculate` finds from the cutoff's inputs at each time, for a new derived subscriber. It sends
    /// a value only when it differs from the last one it sent, and nothing when `calculate` returns `nil`.
    private nonisolated func derivedStream<Value: Sendable & Equatable>(
        _ calculate: @escaping @Sendable (CaffeineCutoffRule.Inputs, Date) -> Value?
    ) -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeDerivedSubscriber(id) }
        }
        let subscriber = DerivedSubscriber { inputs, now, lastSent in
            guard let value = calculate(inputs, now) else { return nil }
            if let lastSent, let last = lastSent as? Value, last == value { return nil }
            continuation.yield(value)
            return value
        }
        Task { await addDerivedSubscriber(id, subscriber) }
        return stream
    }

    /// Starts listening to the drink log before the first value goes out, and follows the clock's minutes after it,
    /// so the first value is always the one for the current time.
    private func addDerivedSubscriber(_ id: UUID, _ subscriber: DerivedSubscriber) async {
        await listenForChanges()
        derivedSubscribers[id] = subscriber
        await publishDerived(at: clock.now(), to: [id])
        listenForMinutes()
    }

    private func removeDerivedSubscriber(_ id: UUID) {
        derivedSubscribers[id] = nil
    }

    private func publishDerivedToEverySubscriber(at now: Date) async {
        await publishDerived(at: now, to: Array(derivedSubscribers.keys))
    }

    /// Reads the cutoff's inputs once, then has each of the derived subscribers `ids` send its value at `now` if it
    /// changed.
    private func publishDerived(at now: Date, to ids: [UUID]) async {
        guard !ids.isEmpty, let inputs = await readCutoffInputs() else { return }
        for id in ids {
            guard var subscriber = derivedSubscribers[id],
                let sent = subscriber.publish(inputs, now, subscriber.lastSent)
            else { continue }
            subscriber.lastSent = sent
            derivedSubscribers[id] = subscriber
        }
    }

    /// Reads the intakes of the drinks that still count, the usual drink from every logged drink, the kinetics, the
    /// threshold, and the bedtime, once for every derived subscriber. Returns `nil`, after logging, if any of them
    /// couldn't be read.
    private func readCutoffInputs() async -> CaffeineCutoffRule.Inputs? {
        do {
            let intakes = try await drinkLog.nonNegligibleDrinks().map(\.intake)
            // The rule fills every slot the log can't with a starter, so there's always a first favourite.
            guard let drink = favouritesRule.favourites(from: try await drinkLog.drinks()).first else { return nil }
            return CaffeineCutoffRule.Inputs(
                drink: drink,
                intakes: intakes,
                kinetics: try await readKinetics(),
                threshold: try await thresholdSource.threshold(),
                bedtime: try await bedtimeSource.bedtime())
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't read the cutoff's inputs: \(domain, privacy: .public) \(code, privacy: .public)")
            return nil
        }
    }
}
