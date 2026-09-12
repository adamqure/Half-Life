//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StandardAbsorptionRateDataSource
//

/// The absorption rate data source until something can store a tuned absorption rate.
///
/// Nothing can store an absorption rate yet, so the current one is always ``CaffeineAbsorptionRate/standard``
/// (ABSORB-1). A per-user or per-drink rate would replace it with a source that stores one.
struct StandardAbsorptionRateDataSource: AbsorptionRateDataSource {
    /// Returns ``CaffeineAbsorptionRate/standard``.
    func absorptionRate() -> CaffeineAbsorptionRate {
        .standard
    }
}
