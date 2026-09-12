//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RestingHeartRateDataSource
//

import Foundation

/// Reads the user's resting heart rate from Apple Health.
///
/// An implementation is the only code that reads resting heart rate from Health (constitution Articles I.14 and
/// V.3.5). No repository reads it yet. The Resting Heart Rate article lists its requirements, RHR-1 to RHR-5.
protocol RestingHeartRateDataSource: Sendable {
    /// Returns the average of the resting heart rates recorded during the calendar day that contains `day`.
    ///
    /// - Parameter day: Any moment in the day to average.
    /// - Returns: The average, in beats per minute, or `nil` if Health has no resting heart rate for that day. It's
    ///   also `nil` when the user has denied read access, because HealthKit doesn't reveal a denial.
    /// - Throws: HealthKit's error if the query failed, for example because the device is locked.
    func averageRestingHeartRate(on day: Date) async throws -> Double?
}
