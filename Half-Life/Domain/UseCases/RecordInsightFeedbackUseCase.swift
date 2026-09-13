//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RecordInsightFeedbackUseCase
//

import Foundation

/// Stores the user's answer to "Feel right?" on the Insights tab's first card, answered now.
///
/// It reads the time from ``CurrentTimeRepository``, because features don't read the clock, and stores the answer
/// through ``InsightFeedbackRepository``, on the device only. See FEEDUSE-2 in the Insights article.
struct RecordInsightFeedbackUseCase: UseCase {
    /// An answer to "Feel right?", with the finding it answered.
    struct Input: Sendable, Equatable {
        /// What the user answered.
        let answer: InsightFeedback.Answer
        /// The finding's confidence.
        let confidence: SleepPattern.Confidence
        /// The finding, in the model's words.
        let insight: Insight
    }

    /// The repository that supplies the current time.
    let currentTime: any CurrentTimeRepository
    /// The repository that stores the answers.
    let repository: any InsightFeedbackRepository

    /// Stores the answer, answered now.
    ///
    /// - Parameter input: The answer, with the finding it answered.
    /// - Throws: The repository's error if the answer couldn't be stored.
    func execute(_ input: Input) async throws {
        try await repository.record(
            InsightFeedback(
                answer: input.answer, confidence: input.confidence, headline: input.insight.headline,
                sentence: input.insight.sentence, answeredAt: currentTime.now()))
    }
}
