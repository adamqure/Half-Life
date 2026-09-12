//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SilentCurrentTimeRepository
//

import Foundation

@testable import Half_Life

/// A current time repository whose stream finishes without a value, for reducer tests that observe something else.
struct SilentCurrentTimeRepository: CurrentTimeRepository {
    /// A fixed date. The reducer tests that use this fake never read it.
    func now() -> Date {
        Date(timeIntervalSinceReferenceDate: 0)
    }

    func currentTime() -> AsyncStream<Date> {
        AsyncStream { $0.finish() }
    }
}
