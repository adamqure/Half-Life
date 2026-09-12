//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StandardSleepThresholdDataSourceTests
//

import Testing

@testable import Half_Life

/// Checks the threshold data source that stands in until the threshold is personalised (THRESH-3 in the Caffeine
/// Cutoff article).
struct StandardSleepThresholdDataSourceTests {

    @Test func returnsTheStandardThreshold() async throws {
        let source: any SleepThresholdDataSource = StandardSleepThresholdDataSource()

        #expect(try await source.threshold() == .standard)
    }
}
