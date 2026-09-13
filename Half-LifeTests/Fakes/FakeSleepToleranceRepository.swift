//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeSleepToleranceRepository
//

import Foundation

@testable import Half_Life

/// A sleep tolerance repository that streams given analyses and caffeine nights, then finishes, for use case and
/// feature tests.
final class FakeSleepToleranceRepository: SleepToleranceRepository {
    /// The analyses each subscriber receives, in order.
    let analyses: [SleepCaffeineAnalysis]
    /// The caffeine night histories a subscriber receives for how many days, in which calendar, in order.
    let caffeineNights: @Sendable (Int, Calendar) -> [CaffeineNightHistory]
    /// How many times ``analysis()`` was subscribed to.
    let subscriptions = Recorded(0)

    init(
        analyses: [SleepCaffeineAnalysis] = [],
        caffeineNights: @escaping @Sendable (Int, Calendar) -> [CaffeineNightHistory] = { _, _ in [] }
    ) {
        self.analyses = analyses
        self.caffeineNights = caffeineNights
    }

    func analysis() -> AsyncStream<SleepCaffeineAnalysis> {
        subscriptions.update { $0 += 1 }
        let analyses = analyses
        return AsyncStream { continuation in
            for analysis in analyses {
                continuation.yield(analysis)
            }
            continuation.finish()
        }
    }

    func caffeineNights(days: Int, in calendar: Calendar) -> AsyncStream<CaffeineNightHistory> {
        let histories = caffeineNights(days, calendar)
        return AsyncStream { continuation in
            for history in histories {
                continuation.yield(history)
            }
            continuation.finish()
        }
    }
}

extension SleepCaffeineAnalysis {
    /// An analysis with no nights, for tests that only need a value to pass along.
    static func empty(isDemo: Bool = false) -> SleepCaffeineAnalysis {
        SleepCaffeineAnalysis(
            nights: [], tolerance: nil, timeAsleep: nil, timeToFallAsleep: nil,
            period: DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 30 * 24 * 3_600), days: 30,
            isDemo: isDemo)
    }
}
