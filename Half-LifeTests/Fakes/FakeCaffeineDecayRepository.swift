//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeCaffeineDecayRepository
//

import Foundation

@testable import Half_Life

/// An in-memory caffeine decay repository for use case tests.
///
/// It streams the curves, statuses, and cutoffs it was given, then finishes. It's an actor, like the live
/// repositories.
actor FakeCaffeineDecayRepository: CaffeineDecayRepository {
    /// The curves that `curve()` streams, in order.
    let curves: [[CaffeineLevel]]
    /// The statuses that `status(in:)` streams for a calendar, in order.
    let statuses: @Sendable (Calendar) -> [CaffeineStatus]
    /// The cutoffs that `cutoff(in:)` streams for a calendar, in order.
    let cutoffs: @Sendable (Calendar) -> [CaffeineCutoff]

    init(
        curves: [[CaffeineLevel]] = [],
        statuses: @escaping @Sendable (Calendar) -> [CaffeineStatus] = { _ in [] },
        cutoffs: @escaping @Sendable (Calendar) -> [CaffeineCutoff] = { _ in [] }
    ) {
        self.curves = curves
        self.statuses = statuses
        self.cutoffs = cutoffs
    }

    nonisolated func cutoff(in calendar: Calendar) -> AsyncStream<CaffeineCutoff> {
        let published = cutoffs(calendar)
        return AsyncStream { continuation in
            for cutoff in published {
                continuation.yield(cutoff)
            }
            continuation.finish()
        }
    }

    nonisolated func status(in calendar: Calendar) -> AsyncStream<CaffeineStatus> {
        let published = statuses(calendar)
        return AsyncStream { continuation in
            for status in published {
                continuation.yield(status)
            }
            continuation.finish()
        }
    }

    nonisolated func curve() -> AsyncStream<[CaffeineLevel]> {
        AsyncStream { continuation in
            for curve in curves {
                continuation.yield(curve)
            }
            continuation.finish()
        }
    }
}
