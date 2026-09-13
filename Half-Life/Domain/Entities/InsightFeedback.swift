//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightFeedback
//

import Foundation

/// The user's answer to "Feel right?" on the Insights tab's first card, with the finding it answered.
///
/// ``InsightFeedbackRule`` decides from the answers whether the card is dismissed and whether it asks, and the last
/// "Not really" goes into the next prompt, so the model takes a different approach. The answers are the user's reaction
/// to their own sleep, so they stay on the device, and are never synced or logged (constitution Articles V.1 and
/// XI.6). See the Insights article.
struct InsightFeedback: Sendable, Equatable {
    /// What the user answered.
    enum Answer: Sendable, Equatable {
        /// "Yes": the finding feels right.
        case agree
        /// "Not really": it doesn't.
        case disagree
    }

    /// What the user answered.
    let answer: Answer
    /// The finding's confidence when the user answered.
    let confidence: SleepPattern.Confidence
    /// The headline the user answered.
    let headline: String
    /// The sentence the user answered.
    let sentence: String
    /// When the user answered.
    let answeredAt: Date
}
