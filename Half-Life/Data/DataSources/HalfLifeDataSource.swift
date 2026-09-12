//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeDataSource
//

/// Supplies the user's half-life to ``CaffeineDecayRepository``, and signals when it changes.
///
/// ``FileProfileDataSource`` implements it from the stored profile. See the Caffeine Decay Model article, HALF-1, and
/// the Onboarding article.
protocol HalfLifeDataSource: Sendable {
    /// Returns the current half-life: the stored one, or ``CaffeineHalfLife/standard`` when nothing is stored.
    ///
    /// - Throws: An error if a stored half-life couldn't be read.
    func halfLife() async throws -> CaffeineHalfLife

    /// Returns a stream that yields once after each change that could change the half-life.
    func changes() async -> AsyncStream<Void>
}
