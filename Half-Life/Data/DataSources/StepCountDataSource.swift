//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepCountDataSource
//

import Foundation

/// Reads the user's daily step count from Apple Health.
///
/// An implementation is the only code that reads step count from Health (constitution Articles I.14 and V.3.5).
/// ``HalfLifeEstimateRepository`` and ``HealthDataRepository`` read it. The Step Count article lists its requirements,
/// STEPS-1 to STEPS-8.
protocol StepCountDataSource: Sendable {
    /// Returns the total number of steps recorded during the calendar day that contains `day`.
    ///
    /// - Parameter day: Any moment in the day to total.
    /// - Returns: The day's steps, or `nil` if Health has no step count for that day. It's also `nil` when the user
    ///   has denied read access, because HealthKit doesn't reveal a denial. It's `0` only when Health recorded zero.
    /// - Throws: HealthKit's error if the query failed, for example because the device is locked.
    func stepCount(on day: Date) async throws -> Int?

    /// Returns a stream for one subscriber that yields each time Health reports that step count may have changed.
    ///
    /// A signal doesn't say what changed, so a subscriber re-reads the steps it needs. The stream ends when its
    /// subscriber stops listening.
    func changes() async -> AsyncStream<Void>
}
