//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeRestingHeartRateDataSource
//

import Foundation

@testable import Half_Life

/// A resting heart rate data source that answers from a closure, for repository tests, so no test reads real Health
/// data.
///
/// It records every date it's asked about.
actor FakeRestingHeartRateDataSource: RestingHeartRateDataSource {
    /// Returns the average resting heart rate for a date, or throws.
    let average: @Sendable (Date) throws -> Double?
    /// The date of each read, in order.
    private(set) var requestedDays: [Date] = []

    init(average: @escaping @Sendable (Date) throws -> Double? = { _ in nil }) {
        self.average = average
    }

    func averageRestingHeartRate(on day: Date) throws -> Double? {
        requestedDays.append(day)
        return try average(day)
    }

    /// Returns a stream that finishes at once: these readings never change.
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
