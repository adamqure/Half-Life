//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeFactor
//

/// Something the user can report that changes how fast they clear caffeine.
///
/// Each case changed the half-life by more than 25% in the studies the Onboarding article cites, and is something a
/// user knows about themselves. ``HalfLifePriorRule`` turns a set of them into the starting half-life.
nonisolated enum HalfLifeFactor: Sendable, Hashable {
    /// Pregnant, in the given trimester.
    case pregnant(Trimester)
    /// Takes estrogen: the combined pill, patch, or ring, or hormone therapy.
    case estrogen
    /// Smokes cigarettes. Vaping and nicotine patches don't count.
    case smokes
    /// Has cirrhosis of the liver.
    case cirrhosis
    /// Takes fluvoxamine.
    case fluvoxamine
}

/// A third of a pregnancy.
nonisolated enum Trimester: Sendable, Hashable, CaseIterable {
    /// Weeks 1 to 13.
    case first
    /// Weeks 14 to 27.
    case second
    /// Week 28 to the birth.
    case third
}
