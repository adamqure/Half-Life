//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightFeedbackDataSource
//

import Foundation

/// Stores the "Feel right?" answers on the Insights tab's first card.
///
/// An implementation keeps them on the device only, and never syncs them (constitution Article V.1). See the Insights
/// article.
protocol InsightFeedbackDataSource: Sendable {
    /// Returns every answer stored, in the order they were recorded, or none if nothing has been stored.
    ///
    /// - Throws: An error if the answers exist but couldn't be read.
    func answers() async throws -> [InsightFeedback]

    /// Adds an answer after the others.
    ///
    /// - Parameter feedback: The answer, with the finding it answered.
    /// - Throws: An error if the answer couldn't be stored.
    func record(_ feedback: InsightFeedback) async throws
}
