//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StandardHalfLifeDataSource
//

/// The half-life data source until the tuning features can store a user's own half-life.
///
/// Nothing can store a half-life yet, so the current one is always ``CaffeineHalfLife/standard`` (HALF-1). The
/// onboarding survey, the personal estimator, and Settings (roadmap ranks 6, 9, and 21) replace it with a source
/// that stores one.
struct StandardHalfLifeDataSource: HalfLifeDataSource {
    /// Returns ``CaffeineHalfLife/standard``.
    func halfLife() -> CaffeineHalfLife {
        .standard
    }
}
