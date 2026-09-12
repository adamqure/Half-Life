//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ClockDataSource
//

import Foundation

/// The only source of the current time: the one place the app reads the system clock.
///
/// ``LiveCurrentTimeRepository`` reads it. The Today Screen article lists its requirements, CLOCK-1 to CLOCK-4,
/// and the Drink Composer article adds CLOCK-5.
protocol ClockDataSource: Sendable {
    /// Returns the current time.
    func now() -> Date

    /// Streams the current time as soon as it's subscribed to, then once at every whole minute.
    ///
    /// The stream finishes when its subscriber stops listening.
    func minutes() -> AsyncStream<Date>
}
