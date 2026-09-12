//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepDataSource
//

import Foundation

/// Reads the user's sleep from Apple Health.
///
/// An implementation is the only code that reads sleep from Health (constitution Articles I.14 and V.3.5). It returns
/// what the trackers recorded, stage by stage, and leaves merging trackers and summarizing each night to a business
/// rule. It never requests authorization, which is the HealthKit authorization data source's job (V.3.1). No
/// repository reads it yet. The Sleep Data article lists its requirements, SLEEP-1 to SLEEP-8.
protocol SleepDataSource: Sendable {
    /// Returns every sleep interval that overlaps `range`, in order of start.
    ///
    /// Intervals keep the times Health recorded, so one can start before `range` or end after it.
    ///
    /// - Parameter range: The time to read sleep for.
    /// - Returns: The intervals, or none if Health has no sleep in `range`. It's also empty when the user hasn't
    ///   allowed reading sleep, because HealthKit doesn't reveal a denial.
    /// - Throws: HealthKit's error if the query failed, for example because the device is locked.
    func sleepIntervals(in range: DateInterval) async throws -> [SleepStageInterval]

    /// Returns a stream for one subscriber that yields each time Health reports that sleep may have changed.
    ///
    /// A signal doesn't say what changed, so a subscriber re-reads the sleep it needs. The stream ends when its
    /// subscriber stops listening.
    func changes() async -> AsyncStream<Void>
}
