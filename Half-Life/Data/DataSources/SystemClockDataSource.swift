//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SystemClockDataSource
//

import Foundation

/// The live clock data source. It reads `Date.now`, and sleeps until each whole minute starts.
///
/// If the app is suspended past a minute, the stream yields the time it wakes at, so it never publishes a stale
/// minute. The clock and the sleep are injected so tests can control time; the defaults are the system's.
struct SystemClockDataSource: ClockDataSource {
    /// Reads the current time.
    let clock: @Sendable () -> Date
    /// Suspends for the given number of seconds. It throws if the sleep is cancelled.
    let sleep: @Sendable (TimeInterval) async throws -> Void

    /// Creates a clock data source.
    ///
    /// - Parameters:
    ///   - clock: Reads the current time. Defaults to `Date.now`.
    ///   - sleep: Suspends for a number of seconds. Defaults to `Task.sleep`, which throws when cancelled.
    init(
        clock: @escaping @Sendable () -> Date = { Date.now },
        sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { try await Task.sleep(for: .seconds($0)) }
    ) {
        self.clock = clock
        self.sleep = sleep
    }

    /// Returns the current time.
    func now() -> Date {
        clock()
    }

    /// Streams the current time as soon as it's subscribed to, then once at every whole minute.
    ///
    /// After each value, it sleeps until the next whole minute, then yields the later of the current time and that
    /// minute. If a sleep is cancelled, including when the subscriber stops listening, the stream finishes.
    func minutes() -> AsyncStream<Date> {
        AsyncStream { continuation in
            let task = Task {
                var latest = clock()
                continuation.yield(latest)
                while true {
                    let minute = Self.wholeMinute(after: latest)
                    do {
                        try await sleep(max(0, minute.timeIntervalSince(clock())))
                    } catch {
                        break
                    }
                    latest = max(clock(), minute)
                    continuation.yield(latest)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Returns the first whole minute strictly after `date`.
    private static func wholeMinute(after date: Date) -> Date {
        let minutes = (date.timeIntervalSinceReferenceDate / 60).rounded(.down) + 1
        return Date(timeIntervalSinceReferenceDate: minutes * 60)
    }
}
