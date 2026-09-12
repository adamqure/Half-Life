//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHalfLifeDataSource
//

@testable import Half_Life

/// A half-life data source that returns a given half-life, for repository tests.
struct FakeHalfLifeDataSource: HalfLifeDataSource {
    /// The half-life that `halfLife()` returns.
    let value: CaffeineHalfLife

    func halfLife() -> CaffeineHalfLife {
        value
    }
}
