//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineHalfLifeTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the half-life entity against the Caffeine Decay Model article's Constants and Entities sections.
struct CaffeineHalfLifeTests {

    @Test func standardIsFiveAndAHalfHours() {
        #expect(CaffeineHalfLife.standard.seconds == 19_800)
    }

    @Test func acceptsPositiveFiniteSeconds() throws {
        let halfLife = try #require(CaffeineHalfLife(seconds: 3_600))
        #expect(halfLife.seconds == 3_600)
    }

    @Test(arguments: [0, -1, -19_800, .nan, .infinity, -.infinity] as [TimeInterval])
    func rejectsSecondsThatArentPositiveAndFinite(_ seconds: TimeInterval) {
        #expect(CaffeineHalfLife(seconds: seconds) == nil)
    }
}
