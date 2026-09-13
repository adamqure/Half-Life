//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SteppedClockDataSource
//

import Foundation

@testable import Half_Life

/// A clock for repository tests that moves only when the test advances it.
///
/// Like the system clock, its minute stream yields the current time as soon as it's subscribed to. After that, it
/// yields each time the test advances it, and never finishes on its own.
final class SteppedClockDataSource: ClockDataSource {
    private let current: Recorded<Date>
    private let continuations = Recorded<[UUID: AsyncStream<Date>.Continuation]>([:])

    init(now: Date) {
        current = Recorded(now)
    }

    func now() -> Date {
        current.value
    }

    func minutes() -> AsyncStream<Date> {
        let (stream, continuation) = AsyncStream.makeStream(of: Date.self)
        let id = UUID()
        continuations.update { $0[id] = continuation }
        continuation.onTermination = { [continuations] _ in
            continuations.update { $0[id] = nil }
        }
        continuation.yield(current.value)
        return stream
    }

    /// Moves the clock to `date`, and streams it to every subscriber as the next minute.
    func advance(to date: Date) {
        current.update { $0 = date }
        for continuation in continuations.value.values {
            continuation.yield(date)
        }
    }
}
