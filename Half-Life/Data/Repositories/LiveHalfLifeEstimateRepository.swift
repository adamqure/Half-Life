//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveHalfLifeEstimateRepository
//

import Foundation
import OSLog

/// The live half-life estimate repository: the source of truth for the user's personal half-life.
///
/// When the estimate is due, it reads the last ``sleepWindow`` of sleep from its ``SleepDataSource`` and turns it into
/// nights with ``SleepNightRule``. For each night, it reads the steps and resting heart rate of the day before: the day
/// that contains the moment ``dayBeforeOffset`` before sleep onset. It reads every drink the user logged, leaving out
/// demo drinks, which real sleep says nothing about, and the survey's starting half-life. Then it executes
/// ``HalfLifeEstimationRule``, stores the estimate through its ``HalfLifeEstimateDataSource``, where the decay model
/// reads it, and publishes it.
///
/// The estimate is due when none is stored, when it's ``recalculationInterval`` old, or when the survey's starting
/// half-life differs from the one it started from. The repository checks when ``refresh()`` is called, when a
/// subscriber arrives, and when the survey's half-life changes, but never on a timer. A step count or resting heart
/// rate that can't be read counts as missing. If anything else can't be read, nothing is stored and the old estimate
/// stays, until the next check. It's an actor, off the main actor (constitution Article I.13). The Half-Life Estimator
/// article lists its requirements, ESTREPO-1 to ESTREPO-8.
actor LiveHalfLifeEstimateRepository: HalfLifeEstimateRepository {
    private static let logger = Logger(for: LiveHalfLifeEstimateRepository.self)

    /// How old an estimate gets before it's recalculated: a week.
    static let recalculationInterval: TimeInterval = 7 * 24 * 3_600
    /// How much sleep is read: the last 90 days.
    static let sleepWindow: TimeInterval = 90 * 24 * 3_600
    /// How long before sleep onset the day before a night is found: 6 hours, so a night that starts after midnight
    /// belongs to the day before.
    static let dayBeforeOffset: TimeInterval = 6 * 3_600

    private let drinkLog: any DrinkLogDataSource
    private let sleep: any SleepDataSource
    private let steps: any StepCountDataSource
    private let restingHeartRate: any RestingHeartRateDataSource
    private let prior: any HalfLifeDataSource
    private let estimates: any HalfLifeEstimateDataSource
    private let absorption: any AbsorptionRateDataSource
    private let clock: any ClockDataSource
    private let calendar: Calendar
    private let nightRule = SleepNightRule()
    private let estimationRule = HalfLifeEstimationRule()
    /// The estimate as last read or calculated, or `nil` until there is one.
    private var current: HalfLifeEstimate?
    private var hasReadStoredEstimate = false
    private var subscribers: [UUID: AsyncStream<HalfLifeEstimate>.Continuation] = [:]
    private var isRefreshing = false
    private var isRecheckRequested = false
    private var isListening = false
    private var surveyListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - drinkLog: The drink log, shared with the other repositories that read drinks.
    ///   - sleep: Where sleep is read from.
    ///   - steps: Where each day's steps are read from.
    ///   - restingHeartRate: Where each day's resting heart rate is read from.
    ///   - prior: Where the survey's starting half-life is read from: the profile.
    ///   - estimates: Where the estimate is stored, shared with the decay model's half-life data source.
    ///   - absorption: Where the absorption rate is read from.
    ///   - clock: The current time.
    ///   - calendar: The calendar whose weekends the estimate allows for. Defaults to the user's current calendar.
    init(
        drinkLog: any DrinkLogDataSource, sleep: any SleepDataSource, steps: any StepCountDataSource,
        restingHeartRate: any RestingHeartRateDataSource, prior: any HalfLifeDataSource,
        estimates: any HalfLifeEstimateDataSource, absorption: any AbsorptionRateDataSource, clock: any ClockDataSource,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.drinkLog = drinkLog
        self.sleep = sleep
        self.steps = steps
        self.restingHeartRate = restingHeartRate
        self.prior = prior
        self.estimates = estimates
        self.absorption = absorption
        self.clock = clock
        self.calendar = calendar
    }

    deinit {
        surveyListener?.cancel()
    }

    /// Streams the estimate: the current one, once it's recalculated if it was due, then each recalculated one.
    nonisolated func estimate() -> AsyncStream<HalfLifeEstimate> {
        let (stream, continuation) = AsyncStream.makeStream(of: HalfLifeEstimate.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Recalculates the estimate if it's due, and publishes it.
    func refresh() async {
        await listenForSurveyChanges()
        await refreshIfDue()
    }

    /// Brings the estimate up to date before the subscriber's first value, so it's never sent a stale one it would
    /// replace at once.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<HalfLifeEstimate>.Continuation) async {
        await listenForSurveyChanges()
        await refreshIfDue()
        subscribers[id] = continuation
        if let current {
            continuation.yield(current)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Subscribes once, for the life of the repository, to changes of the survey's half-life (ESTREPO-4).
    private func listenForSurveyChanges() async {
        guard !isListening else { return }
        isListening = true
        let changes = await prior.changes()
        surveyListener = Task { [weak self] in
            for await _ in changes {
                await self?.refreshIfDue()
            }
        }
    }

    /// Runs one check at a time. A check asked for while one runs makes that one check again when it finishes, so
    /// overlapping refreshes calculate once (ESTREPO-7).
    private func refreshIfDue() async {
        guard !isRefreshing else {
            isRecheckRequested = true
            return
        }
        isRefreshing = true
        repeat {
            isRecheckRequested = false
            await recalculateIfDue()
        } while isRecheckRequested
        isRefreshing = false
    }

    /// Recalculates, stores, and publishes the estimate if it's due.
    private func recalculateIfDue() async {
        await readStoredEstimateOnce()
        guard let surveyed = await readSurveyedHalfLife() else { return }
        let now = clock.now()
        if let current, current.prior == surveyed,
            now < current.calculatedAt.addingTimeInterval(Self.recalculationInterval)
        {
            return
        }
        guard let estimate = await calculate(from: surveyed, now: now) else { return }
        current = estimate
        await store(estimate)
        for subscriber in subscribers.values {
            subscriber.yield(estimate)
        }
        Self.logger.debug("Recalculated the half-life estimate")
    }

    /// Reads the stored estimate the first time it's needed. One that can't be read counts as none, so it's
    /// recalculated.
    private func readStoredEstimateOnce() async {
        guard !hasReadStoredEstimate else { return }
        hasReadStoredEstimate = true
        do {
            current = try await estimates.storedEstimate()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the stored estimate: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
        }
    }

    /// Reads the survey's starting half-life, or returns `nil`, after logging, if it can't be read.
    private func readSurveyedHalfLife() async -> CaffeineHalfLife? {
        do {
            return try await prior.halfLife()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the prior half-life: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
    }

    /// Reads what the estimate needs and executes the rules. Returns `nil`, after logging, if the drinks, the sleep,
    /// or the absorption rate couldn't be read.
    private func calculate(from surveyed: CaffeineHalfLife, now: Date) async -> HalfLifeEstimate? {
        do {
            let intakes = try await drinkLog.drinks().filter { !$0.isDemo }.map(\.intake)
            let range = DateInterval(start: now.addingTimeInterval(-Self.sleepWindow), end: now)
            let intervals = try await sleep.sleepIntervals(in: range)
            let absorptionRate = try await absorption.absorptionRate()
            let nights = await withTheirDays(nightRule.nights(from: intervals))
            let inputs = HalfLifeEstimationRule.Inputs(
                prior: surveyed, nights: nights, intakes: intakes, absorption: absorptionRate)
            return estimationRule.estimate(inputs, calendar: calendar, now: now)
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't calculate the estimate: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
    }

    /// Adds the steps and resting heart rate of the day before each night. A value that can't be read counts as
    /// missing, and the first failure is logged, with its domain and code only.
    private func withTheirDays(_ nights: [SleepNight]) async -> [HalfLifeEstimationRule.Night] {
        var firstFailure: NSError?
        var result: [HalfLifeEstimationRule.Night] = []
        for night in nights {
            let dayBefore = night.sleepOnset.addingTimeInterval(-Self.dayBeforeOffset)
            var stepCount: Int?
            var heartRate: Double?
            do {
                stepCount = try await steps.stepCount(on: dayBefore)
            } catch {
                firstFailure = firstFailure ?? (error as NSError)
            }
            do {
                heartRate = try await restingHeartRate.averageRestingHeartRate(on: dayBefore)
            } catch {
                firstFailure = firstFailure ?? (error as NSError)
            }
            result.append(HalfLifeEstimationRule.Night(sleep: night, steps: stepCount, restingHeartRate: heartRate))
        }
        if let firstFailure {
            Self.logger.error(
                """
                Couldn't read a day's steps or resting heart rate: \(firstFailure.domain, privacy: .public) \
                \(firstFailure.code, privacy: .public)
                """)
        }
        return result
    }

    /// Stores the estimate. A failure is logged and otherwise ignored: the estimate is still published, and it's
    /// recalculated at the next launch, because nothing newer is stored.
    private func store(_ estimate: HalfLifeEstimate) async {
        do {
            try await estimates.store(estimate)
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't store the estimate: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
        }
    }
}
