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
/// Nothing can store a threshold yet, so the current one is always ``SleepThreshold/standard`` (THRESH-3). The
/// personal sensitivity threshold (roadmap rank 22) replaces it with a source that holds the user's own.
struct StandardSleepThresholdDataSource: SleepThresholdDataSource {
    /// Returns ``SleepThreshold/standard``.
    func threshold() -> SleepThreshold {
        .standard
    }
}
