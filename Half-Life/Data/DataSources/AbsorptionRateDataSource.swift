//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AbsorptionRateDataSource
//

/// Reads the caffeine absorption rate from storage.
///
/// An implementation is the only code that touches where the absorption rate is stored (constitution Article I.14).
/// ``LiveCaffeineDecayRepository`` reads it. The Caffeine Decay Model article lists its requirement, ABSORB-1.
protocol AbsorptionRateDataSource: Sendable {
    /// Returns the current absorption rate: the stored one, or ``CaffeineAbsorptionRate/standard`` when nothing is
    /// stored.
    ///
    /// - Throws: An error if a stored absorption rate couldn't be read.
    func absorptionRate() async throws -> CaffeineAbsorptionRate
}
