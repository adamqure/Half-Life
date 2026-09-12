//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineKineticsTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the kinetics entity against the Caffeine Decay Model article's Entities section.
struct CaffeineKineticsTests {

    @Test func standardIsTheStandardHalfLifeAndAbsorptionRate() {
        #expect(CaffeineKinetics.standard.halfLife == .standard)
        #expect(CaffeineKinetics.standard.absorption == .standard)
    }

    @Test func holdsTheHalfLifeAndAbsorptionRateItsGiven() throws {
        let halfLife = try #require(CaffeineHalfLife(seconds: 3_600))
        let absorption = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 600))

        let kinetics = CaffeineKinetics(halfLife: halfLife, absorption: absorption)

        #expect(kinetics.halfLife == halfLife)
        #expect(kinetics.absorption == absorption)
    }
}
