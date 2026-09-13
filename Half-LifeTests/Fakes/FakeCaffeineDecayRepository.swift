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
/// It streams the curves, statuses, cutoffs, and sleep windows it was given, then finishes. It's an actor, like the
/// live repositories.
actor FakeCaffeineDecayRepository: CaffeineDecayRepository {
    /// The curves that `curve()` streams, in order.
    let curves: [[CaffeineLevel]]
    /// The statuses that `status(in:)` streams for a calendar, in order.
    let statuses: @Sendable (Calendar) -> [CaffeineStatus]
    /// The cutoffs that `cutoff(in:)` streams for a calendar, in order.
    let cutoffs: @Sendable (Calendar) -> [CaffeineCutoff]
    /// The values that `upcomingCutoffs(nights:in:)` streams for a number of nights and a calendar, in order.
    let upcoming: @Sendable (Int, Calendar) -> [[CaffeineCutoff]]
    /// The windows that `sleepWindow(in:)` streams for a calendar, in order.
    let sleepWindows: @Sendable (Calendar) -> [SleepWindow]
    /// The values that `cutoffWarning(for:secondsAgo:in:)` streams for a drink, how long ago, and a calendar, in order.
    let warnings: @Sendable (FavouriteDrink, TimeInterval, Calendar) -> [CutoffWarning?]

    init(
        curves: [[CaffeineLevel]] = [],
        statuses: @escaping @Sendable (Calendar) -> [CaffeineStatus] = { _ in [] },
        cutoffs: @escaping @Sendable (Calendar) -> [CaffeineCutoff] = { _ in [] },
        upcoming: @escaping @Sendable (Int, Calendar) -> [[CaffeineCutoff]] = { _, _ in [] },
        sleepWindows: @escaping @Sendable (Calendar) -> [SleepWindow] = { _ in [] },
        warnings: @escaping @Sendable (FavouriteDrink, TimeInterval, Calendar) -> [CutoffWarning?] = { _, _, _ in [] }
    ) {
        self.curves = curves
        self.statuses = statuses
        self.cutoffs = cutoffs
        self.upcoming = upcoming
        self.sleepWindows = sleepWindows
        self.warnings = warnings
    }

    nonisolated func cutoffWarning(
        for drink: FavouriteDrink, secondsAgo: TimeInterval, in calendar: Calendar
    ) -> AsyncStream<CutoffWarning?> {
        let published = warnings(drink, secondsAgo, calendar)
        return AsyncStream { continuation in
            for warning in published {
                continuation.yield(warning)
            }
            continuation.finish()
        }
    }

    nonisolated func sleepWindow(in calendar: Calendar) -> AsyncStream<SleepWindow> {
        let published = sleepWindows(calendar)
        return AsyncStream { continuation in
            for window in published {
                continuation.yield(window)
            }
            continuation.finish()
        }
    }

    nonisolated func upcomingCutoffs(nights: Int, in calendar: Calendar) -> AsyncStream<[CaffeineCutoff]> {
        let published = upcoming(nights, calendar)
        return AsyncStream { continuation in
            for cutoffs in published {
                continuation.yield(cutoffs)
            }
            continuation.finish()
        }
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
