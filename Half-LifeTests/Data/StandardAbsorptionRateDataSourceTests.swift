//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StandardAbsorptionRateDataSourceTests
//

import Testing

@testable import Half_Life

/// Checks ABSORB-1 in the Caffeine Decay Model article.
struct StandardAbsorptionRateDataSourceTests {

    /// Nothing can store a tuned absorption rate yet, so the standard one is the current one.
    @Test func returnsTheStandardAbsorptionRateWhenNothingIsStored() async throws {
        let source: any AbsorptionRateDataSource = StandardAbsorptionRateDataSource()
        #expect(try await source.absorptionRate() == .standard)
    }
}
