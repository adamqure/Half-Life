//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineAbsorptionRate
//

import Foundation

/// How fast caffeine passes from the stomach into the body, expressed as an absorption half-life: the time the gut
/// takes to pass half of the caffeine still in it into the bloodstream.
///
/// It's the decay model's second parameter, next to the elimination ``CaffeineHalfLife``. It's always positive and
/// finite, so a value of this type is always one the model can use. See the Caffeine Decay Model article.
nonisolated struct CaffeineAbsorptionRate: Sendable, Equatable {
    /// The standard absorption half-life of 13 minutes, used until a tuned rate is known. With the standard
    /// half-life, a drink peaks about 63 minutes after it's consumed.
    static let standard = CaffeineAbsorptionRate(validHalfLifeSeconds: 780)

    /// The absorption half-life, in seconds. Always positive and finite.
    let halfLifeSeconds: TimeInterval

    /// Creates an absorption rate, or returns `nil` if `halfLifeSeconds` isn't positive and finite.
    ///
    /// - Parameter halfLifeSeconds: The absorption half-life, in seconds.
    init?(halfLifeSeconds: TimeInterval) {
        guard halfLifeSeconds > 0, halfLifeSeconds.isFinite else { return nil }
        self.halfLifeSeconds = halfLifeSeconds
    }

    private init(validHalfLifeSeconds: TimeInterval) {
        halfLifeSeconds = validHalfLifeSeconds
    }
}
