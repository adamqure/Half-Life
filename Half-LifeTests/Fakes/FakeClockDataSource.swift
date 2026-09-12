//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeClockDataSource
//

import Foundation

@testable import Half_Life

/// A clock data source that returns a fixed time and streams given minutes, for repository tests.
struct FakeClockDataSource: ClockDataSource {
    /// The date that `now()` returns.
    let date: Date
    /// The dates that `minutes()` streams, in order, before it finishes.
    let minuteDates: [Date]

    func now() -> Date {
        date
    }

    func minutes() -> AsyncStream<Date> {
        AsyncStream { continuation in
            for minute in minuteDates {
                continuation.yield(minute)
            }
            continuation.finish()
        }
    }
}
