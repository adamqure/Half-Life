//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHalfLifeEstimateRepository
//

import Foundation

@testable import Half_Life

/// An in-memory half-life estimate repository, for use case and feature tests.
///
/// It streams the estimates it was given, then finishes, and counts refreshes.
actor FakeHalfLifeEstimateRepository: HalfLifeEstimateRepository {
    /// The estimates that `estimate()` streams, in order.
    let streamed: [HalfLifeEstimate]
    /// How many times `refresh()` was called.
    private(set) var refreshCount = 0

    init(streamed: [HalfLifeEstimate] = []) {
        self.streamed = streamed
    }

    nonisolated func estimate() -> AsyncStream<HalfLifeEstimate> {
        AsyncStream { continuation in
            for estimate in streamed {
                continuation.yield(estimate)
            }
            continuation.finish()
        }
    }

    func refresh() {
        refreshCount += 1
    }
}
