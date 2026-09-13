//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UnavailableHealthDataSource
//

import Foundation

/// Stands in for Apple Health wherever the app mustn't read it: previews and UI tests (constitution Article V.3.5).
///
/// It has no sleep, steps, or resting heart rate, as Health looks when access is denied, and its sleep never changes.
/// The Half-Life Estimator article lists its requirement, NOHEALTH-1.
struct UnavailableHealthDataSource: SleepDataSource, StepCountDataSource, RestingHeartRateDataSource {
    /// Returns no sleep.
    func sleepIntervals(in range: DateInterval) -> [SleepStageInterval] {
        []
    }

    /// Returns a stream that finishes at once, because the sleep never changes.
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }

    /// Returns no step count.
    func stepCount(on day: Date) -> Int? {
        nil
    }

    /// Returns no resting heart rate.
    func averageRestingHeartRate(on day: Date) -> Double? {
        nil
    }
}
