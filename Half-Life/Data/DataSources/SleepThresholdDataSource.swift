//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepThresholdDataSource
//

/// Reads the sleep threshold: the most caffeine the cutoff allows in the body at bedtime.
///
/// An implementation is the only code that touches where the threshold is stored (constitution Article I.14).
/// ``LiveCaffeineDecayRepository`` reads it. The Caffeine Cutoff article lists its requirement, THRESH-3.
protocol SleepThresholdDataSource: Sendable {
    /// Returns the current threshold: the user's own once it's personalised, or ``SleepThreshold/standard``.
    ///
    /// - Throws: An error if a stored threshold couldn't be read.
    func threshold() async throws -> SleepThreshold
}
