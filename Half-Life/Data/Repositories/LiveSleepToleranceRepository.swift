//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveSleepToleranceRepository
//

import Foundation
import OSLog

/// The live sleep tolerance repository: the analysis of the user's nights, and the caffeine tolerance it stores for the
/// decay model.
///
/// It reads sleep from Apple Health's sleep data source, or the demo's while the demo switch is on. With the switch
/// off, it reads Health only once access has been requested, as ``HealthDataRepository`` does, and until then there
/// are no nights. It reads every drink while the switch is on, because the demo's nights follow the demo's drinks, and
/// only the user's own drinks while it's off, because real sleep says nothing about demo drinks. The kinetics come
/// from the same half-life and absorption data sources as the curve, so a night's caffeine matches the curve's.
///
/// It executes ``SleepToleranceRule``, stores the tolerance through its ``SleepToleranceDataSource`` whenever it
/// differs from the stored one, none included, and then publishes the analysis to each subscriber, only when it
/// changed. From the same read, it executes ``CaffeineNightRule`` for each caffeine nights subscriber, with the
/// onsets the analysis recognises, the user's bedtime, and the threshold in use, and sends each its own nights when
/// they changed. It recalculates after a change the drink log, the half-life, the bedtime, the switch, or the chosen
/// sleep signals, at the first minute of a new day, and when Health access becomes requested. If an input can't be
/// read, nothing is stored or sent. It's an actor, off the main actor (constitution Article I.13). The caffeine nights
/// are in `LiveSleepToleranceRepository+CaffeineNights.swift`, and storing the tolerance in
/// `LiveSleepToleranceRepository+Storage.swift`. The Insights article lists its requirements, TOLREPO-1 to TOLREPO-11.
actor LiveSleepToleranceRepository: SleepToleranceRepository {
    /// Which sleep the repository reads.
    private enum Mode: Equatable {
        /// The demo's, while the switch is on.
        case demo
        /// Apple Health's, once access has been requested.
        case health
        /// None yet: the switch is off, and Health access hasn't been requested.
        case waitingForAccess
    }

    /// What one read gives: the analysis, and what the caffeine nights are calculated from.
    private struct Reading {
        let analysis: SleepCaffeineAnalysis
        let nightInputs: CaffeineNightRule.Inputs
    }

    /// The repository's logger, which its extensions share.
    static let logger = Logger(for: LiveSleepToleranceRepository.self)

    private let health: any SleepDataSource
    private let demo: any SleepDataSource
    private let authorization: any HealthAuthorizationDataSource
    private let flag: any DemoHealthDataFlagDataSource
    private let drinkLog: any DrinkLogDataSource
    private let halfLife: any HalfLifeDataSource
    private let absorption: any AbsorptionRateDataSource
    private let bedtimeSource: any BedtimeDataSource
    /// Where the tolerance is stored. `LiveSleepToleranceRepository+Storage.swift` stores through it.
    let tolerances: any SleepToleranceDataSource
    private let clock: any ClockDataSource
    /// The calendar whose days the period covers.
    let calendar: Calendar
    /// The rule that finds the nights, the tolerance, and the comparisons.
    let rule = SleepToleranceRule()
    /// The rule that measures each night's caffeine.
    let nightRule = CaffeineNightRule()
    private var subscribers: [UUID: AsyncStream<SleepCaffeineAnalysis>.Continuation] = [:]
    /// The caffeine nights subscribers, which `LiveSleepToleranceRepository+CaffeineNights.swift` serves.
    var nightSubscribers: [UUID: SleepToleranceNightSubscriber] = [:]
    /// The analysis last sent, or `nil` before the first.
    private var current: SleepCaffeineAnalysis?
    /// When the analysis was last read, which tells when its day has turned.
    private var readAt: Date?
    /// The tolerance known to be stored, or `nil` until it's read or stored. The inner `nil` is a stored "none".
    var stored: SleepTolerance??
    private var mode: Mode?
    private var isRecalculating = false
    private var isRecheckRequested = false
    private var starting: Task<Void, Never>?
    private var listeners: [Task<Void, Never>] = []
    private var sleepListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - health: Apple Health's sleep.
    ///   - demo: The demo's sleep, read while the switch is on.
    ///   - authorization: Whether Health access has been requested, shared with the permissions repository.
    ///   - flag: Where the demo switch is stored, shared with the Health data repository.
    ///   - drinkLog: The drink log, shared with the other repositories that read drinks.
    ///   - halfLife: Where the user's half-life is read from: the same data source as the curve's.
    ///   - absorption: Where the absorption rate is read from.
    ///   - bedtime: Where the user's bedtime is read from, for the nights with no recorded onset.
    ///   - tolerances: Where the tolerance is stored, shared with the decay model's threshold data source.
    ///   - clock: The current time, and the minutes the new day and Health access are checked at.
    ///   - calendar: The calendar whose days the period covers. Defaults to the user's current calendar.
    init(
        health: any SleepDataSource, demo: any SleepDataSource, authorization: any HealthAuthorizationDataSource,
        flag: any DemoHealthDataFlagDataSource, drinkLog: any DrinkLogDataSource, halfLife: any HalfLifeDataSource,
        absorption: any AbsorptionRateDataSource, bedtime: any BedtimeDataSource,
        tolerances: any SleepToleranceDataSource, clock: any ClockDataSource, calendar: Calendar = .autoupdatingCurrent
    ) {
        self.health = health
        self.demo = demo
        self.authorization = authorization
        self.flag = flag
        self.drinkLog = drinkLog
        self.halfLife = halfLife
        self.absorption = absorption
        bedtimeSource = bedtime
        self.tolerances = tolerances
        self.clock = clock
        self.calendar = calendar
    }

    deinit {
        for listener in listeners {
            listener.cancel()
        }
        sleepListener?.cancel()
    }

    /// Streams the analysis of the nights in the last 30 days.
    ///
    /// A new subscriber immediately receives the current analysis. After that, it receives a new one whenever the
    /// drinks, the half-life, the chosen sleep, Health access, or a new day changes it.
    nonisolated func analysis() -> AsyncStream<SleepCaffeineAnalysis> {
        let (stream, continuation) = AsyncStream.makeStream(of: SleepCaffeineAnalysis.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<SleepCaffeineAnalysis>.Continuation) async {
        await start()
        subscribers[id] = continuation
        if let current {
            continuation.yield(current)
        } else {
            await recalculate()
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Starts following the switch, the drinks, the half-life, the chosen sleep, and the clock, once, for the life of
    /// the repository. A caller that arrives while it's starting waits for it.
    func start() async {
        if let starting {
            await starting.value
            return
        }
        let task = Task { await beginListening() }
        starting = task
        await task.value
    }

    private func beginListening() async {
        let switchChanges = await flag.changes()
        let dataChanges = [await drinkLog.changes(), await halfLife.changes(), await bedtimeSource.changes()]
        listeners.append(
            Task { [weak self] in
                for await _ in switchChanges {
                    await self?.followChosenSleep()
                    await self?.recalculate()
                }
            })
        for changes in dataChanges {
            listeners.append(
                Task { [weak self] in
                    for await _ in changes {
                        await self?.recalculate()
                    }
                })
        }
        await followChosenSleep()
        let minutes = clock.minutes()
        listeners.append(
            Task { [weak self] in
                for await minute in minutes {
                    await self?.minutePassed(minute)
                }
            })
    }

    /// Follows the change stream of the sleep the switch and Health access choose, in place of any it followed before.
    private func followChosenSleep() async {
        let chosen: Mode
        if await readSwitch() {
            chosen = .demo
        } else {
            chosen = await authorization.status() == .requested ? .health : .waitingForAccess
        }
        guard chosen != mode else { return }
        mode = chosen
        sleepListener?.cancel()
        sleepListener = nil
        guard let source = sleepSource else { return }
        let changes = await source.changes()
        sleepListener = Task { [weak self] in
            for await _ in changes {
                await self?.recalculate()
            }
        }
    }

    /// The sleep the switch and Health access have chosen, or `nil` while waiting for Health access.
    private var sleepSource: (any SleepDataSource)? {
        switch mode {
        case .demo: demo
        case .health: health
        case .waitingForAccess, nil: nil
        }
    }

    /// Reads the switch. If it can't be read, the error is logged with its domain and code only, and it counts as off.
    private func readSwitch() async -> Bool {
        do {
            return try await flag.usesDemoData()
        } catch {
            let error = error as NSError
            Self.logger.error(
                """
                Couldn't read the demo Health data switch: \
                \(error.domain, privacy: .public) \(error.code, privacy: .public)
                """
            )
            return false
        }
    }

    /// While waiting for Health access, checks whether it has been requested, and recalculates once it has. Otherwise
    /// recalculates at the first minute of a new day. The other minutes read nothing.
    private func minutePassed(_ minute: Date) async {
        if mode == .waitingForAccess {
            await followChosenSleep()
            if mode != .waitingForAccess {
                await recalculate(at: minute)
                return
            }
        }
        guard let readAt, !calendar.isDate(minute, inSameDayAs: readAt) else { return }
        await recalculate(at: minute)
    }

    /// Runs one recalculation at a time. One asked for while another runs makes that one run again when it finishes,
    /// so an older analysis is never sent after a newer one.
    func recalculate(at moment: Date? = nil) async {
        guard !isRecalculating else {
            isRecheckRequested = true
            return
        }
        isRecalculating = true
        var moment = moment
        repeat {
            isRecheckRequested = false
            await recalculateOnce(at: moment)
            moment = nil
        } while isRecheckRequested
        isRecalculating = false
    }

    /// Reads the analysis and the caffeine nights at `moment`, or now, stores the tolerance if it changed, and sends
    /// the analysis and each subscriber's nights to those they changed for.
    private func recalculateOnce(at moment: Date?) async {
        let now = moment ?? clock.now()
        guard let reading = await read(at: now) else { return }
        readAt = now
        await storeIfChanged(reading.analysis.tolerance)
        if reading.analysis != current {
            current = reading.analysis
            for continuation in subscribers.values {
                continuation.yield(reading.analysis)
            }
        }
        publishNights(from: reading.nightInputs, now: now)
    }

    /// Reads the drinks, the kinetics, the bedtime, and the chosen sleep, and executes ``SleepToleranceRule``. Returns
    /// `nil`, after logging, if any of them couldn't be read.
    private func read(at now: Date) async -> Reading? {
        let isDemo = mode == .demo
        do {
            let intakes = try await drinkLog.drinks().filter { isDemo || !$0.isDemo }.map(\.intake)
            let kinetics = CaffeineKinetics(
                halfLife: try await halfLife.halfLife(), absorption: try await absorption.absorptionRate())
            let bedtime = try await bedtimeSource.bedtime()
            var intervals: [SleepStageInterval] = []
            if let sleepSource, let range = readRange(at: now) {
                intervals = try await sleepSource.sleepIntervals(in: range)
            }
            let inputs = SleepToleranceRule.Inputs(
                intervals: intervals, intakes: intakes, kinetics: kinetics, isDemo: isDemo)
            guard let analysis = rule.analysis(inputs, now: now, calendar: calendar) else { return nil }
            let nightInputs = CaffeineNightRule.Inputs(
                onsets: rule.onsets(from: intervals, intakes: intakes, now: now), intakes: intakes, kinetics: kinetics,
                bedtime: bedtime, threshold: analysis.threshold, isDemo: isDemo)
            return Reading(analysis: analysis, nightInputs: nightInputs)
        } catch {
            let error = error as NSError
            Self.logger.error(
                """
                Couldn't read the sleep tolerance's inputs: \
                \(error.domain, privacy: .public) \(error.code, privacy: .public)
                """
            )
            return nil
        }
    }
}
