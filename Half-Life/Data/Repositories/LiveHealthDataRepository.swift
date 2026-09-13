//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveHealthDataRepository
//

import Foundation
import OSLog

/// The live Health data repository: today's sleep, steps, and resting heart rate, from Apple Health or the demo.
///
/// It holds two sets of data sources, Apple Health's and the demo's, and reads whichever the demo switch chooses. With
/// the switch off, it reads Health only once access has been requested, which it checks through the
/// ``HealthAuthorizationDataSource`` that ``PermissionsRepository`` also uses. Until then it publishes an empty
/// summary, and checks again at each whole minute. The demo needs no Health access.
///
/// It executes ``LastNightSleepRule`` to find last night. It re-reads the summary when the chosen data sources signal a
/// change, at the first minute of a new day, when the switch turns, and when Health access becomes requested. Each
/// subscriber gets a summary only when it has changed. A metric that can't be read is missing from the summary, and the
/// others still show. It's an actor, off the main actor (constitution Article I.13). The Apple Health Card article
/// lists its requirements, HREPO-1 to HREPO-8. The sleep history for the Insights tab is in an extension, in
/// `LiveHealthDataRepository+SleepHistory.swift`, the available kinds in `LiveHealthDataRepository+Availability.swift`,
/// the resting heart rate history in `LiveHealthDataRepository+RestingHeartRate.swift`, and the step history in
/// `LiveHealthDataRepository+StepHistory.swift`. All are published on the same events (SHREPO-1 to SHREPO-6, AVREPO-1
/// to AVREPO-4, RHRREPO-1 to RHRREPO-6, STEPSREPO-1 to STEPSREPO-6).
actor LiveHealthDataRepository: HealthDataRepository {
    /// Which data the repository reads.
    private enum Mode: Equatable {
        /// The demo data sources, while the switch is on.
        case demo
        /// Apple Health, once access has been requested.
        case health
        /// Nothing yet: the switch is off, and Health access hasn't been requested.
        case waitingForAccess
    }

    /// A summary subscriber: its stream, its calendar, the last summary it was sent, and when that was read.
    private struct SummarySubscriber {
        let calendar: Calendar
        let continuation: AsyncStream<HealthSummary>.Continuation
        var lastSent: HealthSummary?
        var readAt: Date?
    }

    private static let logger = Logger(for: LiveHealthDataRepository.self)
    /// How far before last night's window sleep is read, so a night that started the day before is read whole.
    private static let sleepLookBack: TimeInterval = 24 * 3_600

    private let health: Sources
    private let demo: Sources
    private let authorization: any HealthAuthorizationDataSource
    private let flag: any DemoHealthDataFlagDataSource
    /// The current time, and the minutes the new day and Health access are checked at. The sleep history reads it too.
    let clock: any ClockDataSource
    private let rule = LastNightSleepRule()
    private var summarySubscribers: [UUID: SummarySubscriber] = [:]
    /// The sleep history's subscribers, which `LiveHealthDataRepository+SleepHistory.swift` serves.
    var sleepHistorySubscribers: [UUID: SleepHistorySubscriber] = [:]
    /// The available kinds' subscribers, which `LiveHealthDataRepository+Availability.swift` serves.
    var availabilitySubscribers: [UUID: HealthDataAvailabilitySubscriber] = [:]
    /// The resting heart rate history's subscribers, which `LiveHealthDataRepository+RestingHeartRate.swift` serves.
    var restingHeartRateSubscribers: [UUID: RestingHeartRateSubscriber] = [:]
    /// The step history's subscribers, which `LiveHealthDataRepository+StepHistory.swift` serves.
    var stepHistorySubscribers: [UUID: StepHistorySubscriber] = [:]
    /// Each switch subscriber's stream, and the answer it was last sent.
    private var switchSubscribers: [UUID: (continuation: AsyncStream<Bool>.Continuation, lastSent: Bool?)] = [:]
    private var usesDemo = false
    private var mode: Mode?
    private var starting: Task<Void, Never>?
    private var switchListener: Task<Void, Never>?
    private var minuteListener: Task<Void, Never>?
    private var sourceListeners: [Task<Void, Never>] = []

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - live: Apple Health's data sources.
    ///   - demo: The demo data sources, read while the switch is on.
    ///   - authorization: Whether Health access has been requested, shared with the permissions repository.
    ///   - flag: Where the demo switch is stored.
    ///   - clock: The current time, and the minutes the new day and Health access are checked at.
    init(
        live: Sources, demo: Sources, authorization: any HealthAuthorizationDataSource,
        flag: any DemoHealthDataFlagDataSource, clock: any ClockDataSource
    ) {
        health = live
        self.demo = demo
        self.authorization = authorization
        self.flag = flag
        self.clock = clock
    }

    deinit {
        switchListener?.cancel()
        minuteListener?.cancel()
        for listener in sourceListeners {
            listener.cancel()
        }
    }

    /// Streams today's Health summary in `calendar`.
    ///
    /// A new subscriber immediately receives the current summary. After that, it receives a new summary whenever the
    /// chosen data changes it.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days and noons define today and last night.
    nonisolated func summary(in calendar: Calendar) -> AsyncStream<HealthSummary> {
        let (stream, continuation) = AsyncStream.makeStream(of: HealthSummary.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSummarySubscriber(id) }
        }
        Task { await addSummarySubscriber(id, SummarySubscriber(calendar: calendar, continuation: continuation)) }
        return stream
    }

    /// Streams whether the demo switch is on: the current answer, then each change.
    nonisolated func usesDemoData() -> AsyncStream<Bool> {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSwitchSubscriber(id) }
        }
        Task { await addSwitchSubscriber(id, continuation) }
        return stream
    }

    /// Stores the demo switch. The flag data source signals the change, and the repository publishes the new answer
    /// and the summary from the chosen data.
    ///
    /// - Parameter isOn: Whether to show demo Health data in place of Apple Health's.
    /// - Throws: The flag data source's error if the switch couldn't be stored. It's logged with its domain and code
    ///   only, and nothing changes.
    func setUsesDemoData(_ isOn: Bool) async throws {
        do {
            try await flag.setUsesDemoData(isOn)
        } catch {
            let error = error as NSError
            Self.logger.error(
                """
                Couldn't turn the demo Health data \(isOn ? "on" : "off", privacy: .public): \
                \(error.domain, privacy: .public) \(error.code, privacy: .public)
                """
            )
            throw error
        }
        Self.logger.notice("Demo Health data turned \(isOn ? "on" : "off", privacy: .public)")
    }

    private func addSummarySubscriber(_ id: UUID, _ subscriber: SummarySubscriber) async {
        await start()
        summarySubscribers[id] = subscriber
        await publishSummary(to: [id])
    }

    private func removeSummarySubscriber(_ id: UUID) {
        summarySubscribers[id] = nil
    }

    private func addSwitchSubscriber(_ id: UUID, _ continuation: AsyncStream<Bool>.Continuation) async {
        await start()
        switchSubscribers[id] = (continuation, nil)
        publishSwitch(to: [id])
    }

    private func removeSwitchSubscriber(_ id: UUID) {
        switchSubscribers[id] = nil
    }

    /// Starts following the switch, the chosen data sources, and the clock, once, for the life of the repository. A
    /// caller that arrives while it's starting waits for it, so no summary is read before the switch is known.
    func start() async {
        if let starting {
            await starting.value
            return
        }
        let task = Task { await beginFollowing() }
        starting = task
        await task.value
    }

    private func beginFollowing() async {
        let switchChanges = await flag.changes()
        switchListener = Task { [weak self] in
            for await _ in switchChanges {
                await self?.switchChanged()
            }
        }
        usesDemo = await readSwitch()
        await followChosenSources()
        let minutes = clock.minutes()
        minuteListener = Task { [weak self] in
            for await minute in minutes {
                await self?.minutePassed(minute)
            }
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

    /// Follows the change streams of the data sources the switch and Health access choose, in place of any it followed
    /// before.
    private func followChosenSources() async {
        let chosen: Mode
        if usesDemo {
            chosen = .demo
        } else {
            chosen = await authorization.status() == .requested ? .health : .waitingForAccess
        }
        guard chosen != mode else { return }
        mode = chosen
        for listener in sourceListeners {
            listener.cancel()
        }
        sourceListeners = []
        guard let sources = sources(for: chosen) else { return }
        let streams = [
            await sources.sleep.changes(), await sources.steps.changes(), await sources.restingHeartRate.changes(),
        ]
        sourceListeners = streams.map { changes in
            Task { [weak self] in
                for await _ in changes {
                    await self?.publishSummary(to: nil)
                    await self?.publishSleepHistory(to: nil)
                    await self?.publishAvailableKinds(to: nil)
                    await self?.publishRestingHeartRates(to: nil)
                    await self?.publishStepHistory(to: nil)
                }
            }
        }
    }

    /// The data sources the switch and Health access have chosen, and whether they're the demo's, or `nil` while
    /// waiting for Health access. The sleep history reads them too.
    var chosenSources: (sources: Sources, isDemo: Bool)? {
        sources(for: mode).map { ($0, mode == .demo) }
    }

    private func sources(for mode: Mode?) -> Sources? {
        switch mode {
        case .demo: demo
        case .health: health
        case .waitingForAccess, nil: nil
        }
    }

    /// After the switch signals a change, publishes the new answer, follows the newly chosen data sources, and
    /// publishes their summary.
    private func switchChanged() async {
        let isOn = await readSwitch()
        guard isOn != usesDemo else { return }
        usesDemo = isOn
        publishSwitch(to: Array(switchSubscribers.keys))
        await followChosenSources()
        await publishSummary(to: nil)
        await publishSleepHistory(to: nil)
        await publishAvailableKinds(to: nil)
        await publishRestingHeartRates(to: nil)
        await publishStepHistory(to: nil)
    }

    /// While waiting for Health access, checks whether it has been requested. Then publishes a new summary to each
    /// subscriber whose day has turned by `minute`. The other minutes read nothing.
    private func minutePassed(_ minute: Date) async {
        if mode == .waitingForAccess {
            await followChosenSources()
            if mode != .waitingForAccess {
                await publishSummary(to: nil, at: minute)
                await publishSleepHistory(to: nil, at: minute)
                await publishAvailableKinds(to: nil, at: minute)
                await publishRestingHeartRates(to: nil, at: minute)
                await publishStepHistory(to: nil, at: minute)
                return
            }
        }
        let turned = summarySubscribers.filter { _, subscriber in
            guard let readAt = subscriber.readAt else { return false }
            return !subscriber.calendar.isDate(minute, inSameDayAs: readAt)
        }
        if !turned.isEmpty {
            await publishSummary(to: Array(turned.keys), at: minute)
        }
        await publishSleepHistoryToTurned(at: minute)
        await publishAvailableKindsToTurned(at: minute)
        await publishRestingHeartRatesToTurned(at: minute)
        await publishStepHistoryToTurned(at: minute)
    }

    /// Sends each of the switch subscribers `ids` the switch's answer, if it changed.
    private func publishSwitch(to ids: [UUID]) {
        for id in ids {
            guard let subscriber = switchSubscribers[id], subscriber.lastSent != usesDemo else { continue }
            switchSubscribers[id] = (subscriber.continuation, usesDemo)
            subscriber.continuation.yield(usesDemo)
        }
    }

    /// Reads the summary at `moment`, or now, for each of the summary subscribers `ids`, or for every one, in its own
    /// calendar, and sends it to each it differs for.
    private func publishSummary(to ids: [UUID]?, at moment: Date? = nil) async {
        let now = moment ?? clock.now()
        for id in ids ?? Array(summarySubscribers.keys) {
            guard let calendar = summarySubscribers[id]?.calendar else { continue }
            let summary = await readSummary(at: now, calendar: calendar)
            guard var subscriber = summarySubscribers[id] else { continue }
            subscriber.readAt = now
            if summary != subscriber.lastSent {
                subscriber.lastSent = summary
                subscriber.continuation.yield(summary)
            }
            summarySubscribers[id] = subscriber
        }
    }

    /// Reads today's summary from the chosen data sources. A metric that can't be read is missing; its data source has
    /// logged the error. With nothing chosen, the summary is empty and nothing is read.
    private func readSummary(at now: Date, calendar: Calendar) async -> HealthSummary {
        guard let sources = sources(for: mode) else { return .empty }
        let lastNight = await readLastNight(from: sources.sleep, at: now, calendar: calendar)
        // `try?` flattens the data sources' optionals, so a failed read and a missing value are both `nil`.
        let steps = try? await sources.steps.stepCount(on: now)
        let restingHeartRate = try? await sources.restingHeartRate.averageRestingHeartRate(on: now)
        return HealthSummary(
            lastNight: lastNight, stepsToday: steps, restingHeartRateToday: restingHeartRate, isDemo: mode == .demo)
    }

    /// Reads the sleep around last night, and executes ``LastNightSleepRule`` on it.
    private func readLastNight(
        from sleep: any SleepDataSource, at now: Date, calendar: Calendar
    ) async -> LastNightSleep? {
        guard let window = rule.night(containing: now, calendar: calendar),
            let intervals = try? await sleep.sleepIntervals(
                in: DateInterval(start: window.start.addingTimeInterval(-Self.sleepLookBack), end: window.end))
        else { return nil }
        return rule.lastNight(from: intervals, at: now, calendar: calendar)
    }
}

extension LiveHealthDataRepository {
    /// One set of the three Health data sources: Apple Health's, or the demo's.
    struct Sources: Sendable {
        /// Where sleep is read.
        let sleep: any SleepDataSource
        /// Where step count is read.
        let steps: any StepCountDataSource
        /// Where resting heart rate is read.
        let restingHeartRate: any RestingHeartRateDataSource

        /// Creates a set from its three data sources.
        ///
        /// - Parameters:
        ///   - sleep: Where sleep is read.
        ///   - steps: Where step count is read.
        ///   - restingHeartRate: Where resting heart rate is read.
        init(
            sleep: any SleepDataSource, steps: any StepCountDataSource,
            restingHeartRate: any RestingHeartRateDataSource
        ) {
            self.sleep = sleep
            self.steps = steps
            self.restingHeartRate = restingHeartRate
        }

        /// Creates a set whose three data sources are one type that reads all three.
        ///
        /// - Parameter source: The data source for sleep, step count, and resting heart rate.
        init(_ source: some SleepDataSource & StepCountDataSource & RestingHeartRateDataSource) {
            self.init(sleep: source, steps: source, restingHeartRate: source)
        }
    }
}
