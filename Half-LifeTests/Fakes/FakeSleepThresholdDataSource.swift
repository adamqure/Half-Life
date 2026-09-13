//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeSleepThresholdDataSource
//

@testable import Half_Life

/// A sleep threshold data source that returns a given threshold, for repository tests.
struct FakeSleepThresholdDataSource: SleepThresholdDataSource {
    /// The threshold that `threshold()` returns.
    let value: SleepThreshold

    func threshold() -> SleepThreshold {
        value
    }

    /// Returns a stream that finishes at once, because the threshold never changes.
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
