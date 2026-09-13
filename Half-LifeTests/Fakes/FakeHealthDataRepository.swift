//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHealthDataRepository
//

import Foundation

@testable import Half_Life

/// A Health data repository for use case and reducer tests.
///
/// Its streams send the given values, then finish. It records every value it's asked to store, and can be told to fail
/// the store.
struct FakeHealthDataRepository: HealthDataRepository {
    /// The summaries the summary stream sends for a calendar.
    let summaries: @Sendable (Calendar) -> [HealthSummary]
    /// The answers the switch stream sends.
    let demoAnswers: [Bool]
    /// The histories the sleep history stream sends for a number of days and a calendar.
    let histories: @Sendable (Int, Calendar) -> [SleepHistory]
    /// The sets of kinds the available kinds stream sends for a number of days and a calendar.
    let availableKindSets: @Sendable (Int, Calendar) -> [Set<HealthDataKind>]
    /// The histories the resting heart rate stream sends for a number of days and a calendar.
    let restingHeartRateHistories: @Sendable (Int, Calendar) -> [RestingHeartRateHistory]
    /// The histories the step history stream sends for a number of days and a calendar.
    let stepHistories: @Sendable (Int, Calendar) -> [StepHistory]
    /// The error a store throws, if any.
    let setError: (any Error)?
    /// Every value the repository was asked to store, in order.
    let storedValues = Recorded<[Bool]>([])

    init(
        summaries: @escaping @Sendable (Calendar) -> [HealthSummary] = { _ in [] }, demoAnswers: [Bool] = [],
        histories: @escaping @Sendable (Int, Calendar) -> [SleepHistory] = { _, _ in [] },
        availableKinds: @escaping @Sendable (Int, Calendar) -> [Set<HealthDataKind>] = { _, _ in [] },
        restingHeartRates: @escaping @Sendable (Int, Calendar) -> [RestingHeartRateHistory] = { _, _ in [] },
        stepHistories: @escaping @Sendable (Int, Calendar) -> [StepHistory] = { _, _ in [] },
        setError: (any Error)? = nil
    ) {
        self.summaries = summaries
        self.demoAnswers = demoAnswers
        self.histories = histories
        self.availableKindSets = availableKinds
        self.restingHeartRateHistories = restingHeartRates
        self.stepHistories = stepHistories
        self.setError = setError
    }

    func restingHeartRates(days: Int, in calendar: Calendar) -> AsyncStream<RestingHeartRateHistory> {
        let values = restingHeartRateHistories(days, calendar)
        return AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    func stepHistory(days: Int, in calendar: Calendar) -> AsyncStream<StepHistory> {
        let values = stepHistories(days, calendar)
        return AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    func summary(in calendar: Calendar) -> AsyncStream<HealthSummary> {
        let values = summaries(calendar)
        return AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    func sleepHistory(days: Int, in calendar: Calendar) -> AsyncStream<SleepHistory> {
        let values = histories(days, calendar)
        return AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    func availableKinds(days: Int, in calendar: Calendar) -> AsyncStream<Set<HealthDataKind>> {
        let values = availableKindSets(days, calendar)
        return AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    func usesDemoData() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            for answer in demoAnswers {
                continuation.yield(answer)
            }
            continuation.finish()
        }
    }

    func setUsesDemoData(_ isOn: Bool) async throws {
        storedValues.update { $0.append(isOn) }
        if let setError { throw setError }
    }
}
