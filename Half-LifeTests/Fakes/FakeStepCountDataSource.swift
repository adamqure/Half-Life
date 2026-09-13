//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeStepCountDataSource
//

import Foundation

@testable import Half_Life

/// A step count data source that answers from a closure, for repository tests, so no test reads real Health data.
///
/// It records every date it's asked about.
actor FakeStepCountDataSource: StepCountDataSource {
    /// Returns the steps for a date, or throws.
    let steps: @Sendable (Date) throws -> Int?
    /// The date of each read, in order.
    private(set) var requestedDays: [Date] = []

    init(steps: @escaping @Sendable (Date) throws -> Int? = { _ in nil }) {
        self.steps = steps
    }

    func stepCount(on day: Date) throws -> Int? {
        requestedDays.append(day)
        return try steps(day)
    }

    /// Returns a stream that finishes at once: these steps never change.
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
