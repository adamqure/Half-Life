//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineKinetics
//

import Foundation

/// The decay model's two parameters together: how fast caffeine reaches the body, and how fast the body clears it.
///
/// The two always travel together, so the rules take them as one value. Each is still its own entity, read from its
/// own data source. See the Caffeine Decay Model article.
nonisolated struct CaffeineKinetics: Sendable, Equatable {
    /// The standard parameters: ``CaffeineHalfLife/standard`` and ``CaffeineAbsorptionRate/standard``.
    static let standard = CaffeineKinetics(halfLife: .standard, absorption: .standard)

    /// The elimination half-life.
    let halfLife: CaffeineHalfLife
    /// The rate each intake passes from the stomach into the body.
    let absorption: CaffeineAbsorptionRate
}
