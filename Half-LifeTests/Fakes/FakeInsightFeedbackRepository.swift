//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeInsightFeedbackRepository
//

import Foundation

@testable import Half_Life

/// An insight feedback repository for use case and reducer tests. Its stream sends the given sets of answers, then
/// finishes, and it records every answer it's asked to store.
struct FakeInsightFeedbackRepository: InsightFeedbackRepository {
    /// The sets of answers the stream sends, in order.
    let sets: [[InsightFeedback]]
    /// The error a record throws, if any.
    let recordError: (any Error)?
    /// Every answer the repository was asked to store, in order.
    let recorded = Recorded<[InsightFeedback]>([])

    init(sets: [[InsightFeedback]] = [], recordError: (any Error)? = nil) {
        self.sets = sets
        self.recordError = recordError
    }

    func feedback() -> AsyncStream<[InsightFeedback]> {
        let values = sets
        return AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    func record(_ feedback: InsightFeedback) async throws {
        recorded.update { $0.append(feedback) }
        if let recordError { throw recordError }
    }
}
