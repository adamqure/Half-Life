//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HKHealthStoreHalfLifeTests
//

import HealthKit
import Testing

@testable import Half_Life

/// Checks STORE-1 in the Sleep Data article: every HealthKit data source shares one health store.
struct HKHealthStoreHalfLifeTests {

    /// Apple recommends one long-lived health store per app. Creating a store reads no Health data.
    @Test func theAppHasOneHealthStore() {
        #expect(HKHealthStore.halfLife === HKHealthStore.halfLife)
    }
}
