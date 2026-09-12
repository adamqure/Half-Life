//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifePriorRule
//

import Foundation

/// Calculates the starting half-life from what the user reported about themselves.
///
/// The starting half-life is ``CaffeineHalfLife/standard`` times each factor's multiplier. Pregnancy and estrogen slow
/// the same enzyme, so only the larger of their multipliers applies. The other factors multiply. The result is
/// clamped to 3 to 40 hours. The Onboarding article gives each multiplier's evidence, and lists the rule's
/// requirements, PRIOR-1 to PRIOR-4. It's stateless, and ``UserProfileRepository`` executes it.
nonisolated struct HalfLifePriorRule {
    /// The shortest starting half-life: 3 hours.
    static let minimumSeconds: TimeInterval = 3 * 3_600
    /// The longest starting half-life: 40 hours.
    static let maximumSeconds: TimeInterval = 40 * 3_600

    /// Returns the starting half-life for `factors`.
    ///
    /// - Parameter factors: What the user reported. Empty gives the standard half-life.
    /// - Returns: The standard half-life times the factors' multipliers, clamped to 3 to 40 hours.
    func halfLife(for factors: Set<HalfLifeFactor>) -> CaffeineHalfLife {
        var hormonal = 1.0
        var others = 1.0
        for factor in factors {
            switch factor {
            case .pregnant(let trimester):
                hormonal = max(hormonal, Self.multiplier(for: trimester))
            case .estrogen:
                hormonal = max(hormonal, 1.5)
            case .smokes:
                others *= 0.6
            case .cirrhosis:
                others *= 2.5
            case .fluvoxamine:
                others *= 6
            }
        }
        return halfLife(multiplier: hormonal * others)
    }

    /// Returns the standard half-life times `multiplier`, clamped to 3 to 40 hours.
    ///
    /// - Parameter multiplier: The combined multiplier. Always positive.
    /// - Returns: The clamped half-life.
    func halfLife(multiplier: Double) -> CaffeineHalfLife {
        let seconds = min(
            max(CaffeineHalfLife.standard.seconds * multiplier, Self.minimumSeconds), Self.maximumSeconds)
        // The clamp keeps `seconds` positive and finite, so the half-life always exists.
        return CaffeineHalfLife(seconds: seconds) ?? .standard
    }

    /// The multiplier for a pregnancy in `trimester`.
    private static func multiplier(for trimester: Trimester) -> Double {
        switch trimester {
        case .first: 1.5
        case .second: 1.9
        case .third: 2.7
        }
    }
}
