//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StandardSleepThresholdDataSource
//

/// The sleep threshold data source until the threshold is personalised.
///
/// Its threshold is always ``SleepThreshold/standard`` (THRESH-3). The app uses
/// ``PersonalSleepThresholdDataSource``, which serves the user's caffeine tolerance, so this one stands in only where
/// a repository is built without a threshold, as in tests.
struct StandardSleepThresholdDataSource: SleepThresholdDataSource {
    /// Returns ``SleepThreshold/standard``.
    func threshold() -> SleepThreshold {
        .standard
    }

    /// Returns a stream that finishes at once, because the standard threshold never changes (THRESH-4).
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
