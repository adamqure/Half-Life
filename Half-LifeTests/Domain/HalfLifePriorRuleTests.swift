//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HalfLifePriorRuleTests
//

import Foundation
import Testing

@testable import Half_Life

struct HalfLifePriorRuleTests {

    let rule = HalfLifePriorRule()

    /// Hours, in seconds.
    static func hours(_ hours: Double) -> TimeInterval {
        hours * 3_600
    }

    func expectHalfLife(
        _ factors: Set<HalfLifeFactor>, is hours: Double, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let seconds = rule.halfLife(for: factors).seconds
        #expect(abs(seconds - Self.hours(hours)) < 0.001, "\(seconds) s", sourceLocation: sourceLocation)
    }

    // MARK: - PRIOR-1: no factors give the standard half-life

    @Test func noFactorsGiveTheStandardHalfLife() {
        #expect(rule.halfLife(for: []) == .standard)
    }

    // MARK: - PRIOR-2: each factor alone

    @Test func eachTrimesterLengthensTheHalfLifeByItsMultiplier() {
        expectHalfLife([.pregnant(.first)], is: 8.25)
        expectHalfLife([.pregnant(.second)], is: 10.45)
        expectHalfLife([.pregnant(.third)], is: 14.85)
    }

    @Test func estrogenLengthensTheHalfLifeByHalf() {
        expectHalfLife([.estrogen], is: 8.25)
    }

    @Test func smokingShortensTheHalfLife() {
        expectHalfLife([.smokes], is: 3.3)
    }

    @Test func cirrhosisLengthensTheHalfLife() {
        expectHalfLife([.cirrhosis], is: 13.75)
    }

    @Test func fluvoxamineLengthensTheHalfLifeSixfold() {
        expectHalfLife([.fluvoxamine], is: 33)
    }

    // MARK: - PRIOR-3: pregnancy and estrogen don't stack, and the rest multiply

    @Test func pregnancyAndEstrogenTakeTheLargerMultiplier() {
        expectHalfLife([.pregnant(.third), .estrogen], is: 14.85)
        expectHalfLife([.pregnant(.first), .estrogen], is: 8.25)
    }

    @Test func otherFactorsMultiply() {
        expectHalfLife([.smokes, .estrogen], is: 4.95)
        expectHalfLife([.smokes, .cirrhosis], is: 8.25)
        expectHalfLife([.smokes, .pregnant(.second), .estrogen], is: 6.27)
    }

    // MARK: - PRIOR-4: the result stays within 3 to 40 hours

    @Test func theResultIsNeverAboveFortyHours() {
        expectHalfLife([.fluvoxamine, .cirrhosis], is: 40)
    }

    @Test func theResultIsNeverBelowThreeHours() {
        #expect(rule.halfLife(multiplier: 0.1).seconds == Self.hours(3))
        #expect(rule.halfLife(multiplier: 100).seconds == Self.hours(40))
    }
}
