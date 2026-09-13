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

    /// Starts an observer query for `type` on the app's shared store, and returns a function that stops it.
    ///
    /// The step count and resting heart rate data sources' change streams run through it, one query per subscriber.
    ///
    /// - Parameters:
    ///   - type: The sample type to observe.
    ///   - handler: Called with `nil` after each change HealthKit reports, or with the error it reported.
    /// - Returns: A function that stops the query.
    static func observeHalfLife(
        _ type: HKSampleType, handler: @escaping @Sendable ((any Error)?) -> Void
    ) -> @Sendable () -> Void {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
            handler(error)
            completionHandler()
        }
        HKHealthStore.halfLife.execute(query)
        return { HKHealthStore.halfLife.stop(query) }
    }
}
