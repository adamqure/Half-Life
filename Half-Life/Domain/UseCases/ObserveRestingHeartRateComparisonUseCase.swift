//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveRestingHeartRateComparisonUseCase
//

import Foundation

/// Streams the user's resting heart rate on the days after a caffeine night, against the other days, over the last 30
/// days.
///
/// It combines two repositories' streams: the caffeine of each night, which ``SleepToleranceRepository`` publishes for
/// every comparison on the Insights tab, and each day's resting heart rate, from ``HealthDataRepository``. Once both
/// have sent a value, it executes ``RestingHeartRateComparisonRule`` on the latest of each, and sends the comparison
/// whenever it changes. The owner chose on 2026-09-13 to combine them here rather than give one repository the
/// other's data, so it's one of the use cases that execute a business rule, each an exception the owner approved (the
/// Architecture article). It holds no state between calls. The Insights tab's resting heart rate screen observes it.
/// See the Insights article.
struct ObserveRestingHeartRateComparisonUseCase: UseCase {
    /// How many days of resting heart rate it compares, today included, each with the night before it.
    static let dayCount = 30

    /// The repository that owns each night's caffeine.
    let sleepTolerance: any SleepToleranceRepository
    /// The repository that owns the Health data.
    let healthData: any HealthDataRepository

    /// A value from one of the two streams.
    private enum Update: Sendable {
        case nights(CaffeineNightHistory)
        case heartRates(RestingHeartRateHistory)
    }

    /// Returns a stream of the comparison: the first once both repositories have sent a value, then each change. It
    /// finishes when both repositories' streams have.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days are compared.
    func execute(_ calendar: Calendar) -> AsyncStream<RestingHeartRateComparison> {
        let updates = Self.merge(
            sleepTolerance.caffeineNights(days: Self.dayCount, in: calendar),
            healthData.restingHeartRates(days: Self.dayCount, in: calendar))
        let rule = RestingHeartRateComparisonRule()
        return AsyncStream { continuation in
            let task = Task {
                var nights: CaffeineNightHistory?
                var heartRates: RestingHeartRateHistory?
                var lastSent: RestingHeartRateComparison?
                for await update in updates {
                    switch update {
                    case let .nights(value): nights = value
                    case let .heartRates(value): heartRates = value
                    }
                    guard let nights, let heartRates else { continue }
                    let comparison = rule.comparison(of: heartRates, with: nights, calendar: calendar)
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
        _ nights: AsyncStream<CaffeineNightHistory>, _ heartRates: AsyncStream<RestingHeartRateHistory>
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
                        for await value in heartRates {
                            continuation.yield(.heartRates(value))
                        }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
