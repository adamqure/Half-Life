//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserProfile
//

/// What the user has told the app about themselves, and the half-life that follows from it.
///
/// Onboarding fills it in. Everything is optional, so a profile with nothing given holds the defaults: no name or
/// age, no factors, the standard bedtime and half-life, and onboarding not yet completed. See the Onboarding and Today
/// Screen articles.
nonisolated struct UserProfile: Sendable, Equatable {
    /// The user's first name, or `nil` until they've given it.
    let name: String?
    /// The year the user's age implies, or `nil` until they've given an age.
    let birthYear: Int?
    /// What the user said changes how fast they clear caffeine. Empty means none of them.
    let halfLifeFactors: Set<HalfLifeFactor>
    /// When the user wants to be asleep.
    let bedtime: Bedtime
    /// The half-life the decay model uses for the user: the one ``HalfLifePriorRule`` gives for their factors.
    let halfLife: CaffeineHalfLife
    /// Whether the user has finished onboarding.
    let hasCompletedOnboarding: Bool

    /// Creates a profile. Anything left out takes its default.
    ///
    /// - Parameters:
    ///   - name: The user's first name, or `nil`.
    ///   - birthYear: The year the user's age implies, or `nil`.
    ///   - halfLifeFactors: What changes how fast the user clears caffeine.
    ///   - bedtime: When the user wants to be asleep.
    ///   - halfLife: The half-life the decay model uses for the user.
    ///   - hasCompletedOnboarding: Whether the user has finished onboarding.
    init(
        name: String? = nil, birthYear: Int? = nil, halfLifeFactors: Set<HalfLifeFactor> = [],
        bedtime: Bedtime = .standard, halfLife: CaffeineHalfLife = .standard, hasCompletedOnboarding: Bool = false
    ) {
        self.name = name
        self.birthYear = birthYear
        self.halfLifeFactors = halfLifeFactors
        self.bedtime = bedtime
        self.halfLife = halfLife
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
