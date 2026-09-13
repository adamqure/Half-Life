//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightFeedbackRepository
//

import Foundation

/// The source of truth for the "Feel right?" answers on the Insights tab's first card.
///
/// It stores the answers through a data source on the device only, and publishes them (constitution Article I.12).
/// See the Insights article, FEEDREPO-1 to FEEDREPO-3.
protocol InsightFeedbackRepository: Sendable {
    /// Streams every answer stored, in the order given: the current ones as soon as it's subscribed to, then the new
    /// set after each answer is recorded.
    func feedback() -> AsyncStream<[InsightFeedback]>

    /// Stores an answer. Subscribers get the new set once it's stored.
    ///
    /// - Parameter feedback: The answer, with the finding it answered.
    /// - Throws: An error if the answer couldn't be stored. Nothing changes then.
    func record(_ feedback: InsightFeedback) async throws
}
