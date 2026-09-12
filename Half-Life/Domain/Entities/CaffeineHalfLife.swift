//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineHalfLife
//

import Foundation

/// A person's caffeine elimination half-life: the time their body takes to clear half the caffeine present.
///
/// The half-life is the decay model's only per-user parameter. It's always positive and finite, so a value of
/// this type is always one the model can use. See the Caffeine Decay Model article.
nonisolated struct CaffeineHalfLife: Sendable, Equatable {
    /// The standard half-life of 5.5 hours, used until the user's own half-life is known.
    static let standard = CaffeineHalfLife(validSeconds: 19_800)

    /// The half-life, in seconds. Always positive and finite.
    let seconds: TimeInterval

    /// Creates a half-life, or returns `nil` if `seconds` isn't positive and finite.
    ///
    /// - Parameter seconds: The half-life, in seconds.
    init?(seconds: TimeInterval) {
        guard seconds > 0, seconds.isFinite else { return nil }
        self.seconds = seconds
    }

    private init(validSeconds: TimeInterval) {
        seconds = validSeconds
    }
}
