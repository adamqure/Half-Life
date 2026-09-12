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

/// Reads the user's caffeine half-life from storage.
///
/// An implementation is the only code that touches where the half-life is stored (constitution Article I.14).
/// ``LiveCaffeineDecayRepository`` reads it. The Caffeine Decay Model article lists its requirement, HALF-1.
protocol HalfLifeDataSource: Sendable {
    /// Returns the current half-life: the stored one, or ``CaffeineHalfLife/standard`` when nothing is stored.
    ///
    /// - Throws: An error if a stored half-life couldn't be read.
    func halfLife() async throws -> CaffeineHalfLife
}
