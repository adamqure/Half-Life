//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StandardHalfLifeDataSourceTests
//

import Testing

@testable import Half_Life

/// Checks HALF-1 in the Caffeine Decay Model article.
struct StandardHalfLifeDataSourceTests {

    /// Nothing can store a tuned half-life yet, so the standard one is the current one.
    @Test func returnsTheStandardHalfLifeWhenNothingIsStored() async throws {
        let source: any HalfLifeDataSource = StandardHalfLifeDataSource()
        #expect(try await source.halfLife() == .standard)
    }
}
