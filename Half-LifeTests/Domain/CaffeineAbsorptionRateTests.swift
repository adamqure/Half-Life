//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineAbsorptionRateTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the absorption rate entity against the Caffeine Decay Model article's Constants and Entities sections.
struct CaffeineAbsorptionRateTests {

    @Test func standardIsAThirteenMinuteAbsorptionHalfLife() {
        #expect(CaffeineAbsorptionRate.standard.halfLifeSeconds == 780)
    }

    @Test func acceptsPositiveFiniteSeconds() throws {
        let rate = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 600))
        #expect(rate.halfLifeSeconds == 600)
    }

    @Test(arguments: [0, -1, -780, .nan, .infinity, -.infinity] as [TimeInterval])
    func rejectsSecondsThatArentPositiveAndFinite(_ seconds: TimeInterval) {
        #expect(CaffeineAbsorptionRate(halfLifeSeconds: seconds) == nil)
    }
}
