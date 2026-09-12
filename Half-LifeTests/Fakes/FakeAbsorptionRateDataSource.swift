//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeAbsorptionRateDataSource
//

@testable import Half_Life

/// An absorption rate data source that returns a given absorption rate, for repository tests.
struct FakeAbsorptionRateDataSource: AbsorptionRateDataSource {
    /// The absorption rate that `absorptionRate()` returns.
    let value: CaffeineAbsorptionRate

    func absorptionRate() -> CaffeineAbsorptionRate {
        value
    }
}
