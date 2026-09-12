//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CurrentTimeRepository
//

import Foundation

/// The source of truth for the current time.
///
/// An implementation reads the time from a current time data source, so tests can stop the clock. See the Drink
/// Composer article.
protocol CurrentTimeRepository: Sendable {
    /// Returns the current time.
    func now() -> Date

    /// Streams the current time: once immediately on subscription, then at the start of each whole minute.
    func currentTime() -> AsyncStream<Date>
}
