//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StandardBedtimeDataSourceTests
//

import Testing

@testable import Half_Life

/// Checks the bedtime data source that stands in until onboarding stores a bedtime (BEDSRC-1 in the Today Screen
/// article).
struct StandardBedtimeDataSourceTests {

    @Test func returnsTheStandardBedtime() async throws {
        let source: any BedtimeDataSource = StandardBedtimeDataSource()

        #expect(try await source.bedtime() == .standard)
    }
}
