//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HKHealthStore+HalfLife
//

import HealthKit

extension HKHealthStore {
    /// The app's health store, shared by every HealthKit data source.
    ///
    /// Apple recommends one long-lived store per app. Only data sources use it (constitution Article I.14), and
    /// creating it reads no Health data. The Sleep Data article lists its requirement, STORE-1.
    static let halfLife = HKHealthStore()
}
