//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeCurrentTimeRepository
//

import Foundation

@testable import Half_Life

/// A current time repository whose clock is stopped at a fixed date, for use case tests.
struct FakeCurrentTimeRepository: CurrentTimeRepository {
    /// The date that `now()` returns and `currentTime()` emits.
    let date: Date

    func now() -> Date {
        date
    }

    func currentTime() -> AsyncStream<Date> {
        AsyncStream { continuation in
            continuation.yield(date)
            continuation.finish()
        }
    }
}
