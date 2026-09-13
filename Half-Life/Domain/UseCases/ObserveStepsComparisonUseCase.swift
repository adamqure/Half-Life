//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveStepsComparisonUseCase
//

import Foundation

/// Streams the user's steps on the days after a caffeine night, against the other days, over the last 30 days.
///
/// It combines two repositories' streams: the caffeine of each night, which ``SleepToleranceRepository`` publishes for
/// every comparison on the Insights tab, and each day's steps, from ``HealthDataRepository``. Once both have sent a
/// value, it executes ``StepsComparisonRule`` on the latest of each, and sends the comparison whenever it changes. The
/// owner chose on 2026-09-13 to combine them here rather than give one repository the other's data, so it's one of the
/// use cases that execute a business rule (the Architecture article). It holds no state between calls. The Insights
/// tab's steps screen observes it. See the Insights article, STEPSUSE-1 to STEPSUSE-3.
struct ObserveStepsComparisonUseCase: UseCase {
    /// The repository that owns each night's caffeine.
    let sleepTolerance: any SleepToleranceRepository
    /// The repository that owns the Health data.
    let healthData: any HealthDataRepository

    /// A value from one of the two streams.
    private enum Update: Sendable {
        case nights(CaffeineNightHistory)
        case steps(StepHistory)
    }

    /// Returns a stream of the comparison: the first once both repositories have sent a value, then each change. It
    /// finishes when both repositories' streams have.
    ///
    /// It reads 31 nights, so the first of the 30 days has the night before it.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days are compared.
    func execute(_ calendar: Calendar) -> AsyncStream<StepsComparison> {
        let updates = Self.merge(
            sleepTolerance.caffeineNights(days: StepsComparisonRule.dayCount + 1, in: calendar),
            healthData.stepHistory(days: StepsComparisonRule.dayCount, in: calendar))
        let rule = StepsComparisonRule()
        return AsyncStream { continuation in
            let task = Task {
                var nights: CaffeineNightHistory?
                var steps: StepHistory?
                var lastSent: StepsComparison?
                for await update in updates {
                    switch update {
                    case let .nights(value): nights = value
                    case let .steps(value): steps = value
                    }
                    guard let nights, let steps else { continue }
                    let comparison = rule.comparison(
                        caffeineNightDays: Set(nights.nights.filter(\.isCaffeineNight).map(\.day)),
                        threshold: nights.threshold, steps: steps, calendar: calendar)
                    guard comparison != lastSent else { continue }
                    lastSent = comparison
                    continuation.yield(comparison)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// One stream of both streams' values, in the order they arrive. It finishes when both have.
    private static func merge(
        _ nights: AsyncStream<CaffeineNightHistory>, _ steps: AsyncStream<StepHistory>
    ) -> AsyncStream<Update> {
        AsyncStream { continuation in
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await value in nights {
                            continuation.yield(.nights(value))
                        }
                    }
                    group.addTask {
                        for await value in steps {
                            continuation.yield(.steps(value))
                        }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
