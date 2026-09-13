//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightFeedbackRule
//

import Foundation

/// What the "Feel right?" answers do to the Insights tab's first card.
///
/// The latest answer decides, while the finding's confidence is the one the user answered at. "Not really" dismisses
/// the card, and "Yes" keeps the card but stops asking. When the confidence changes, the card shows and asks again. The
/// latest "Not really", at any confidence, is the one the next prompt quotes. It holds no state. See the Insights
/// article, FEEDBACK-1 to FEEDBACK-4.
struct InsightFeedbackRule {
    /// What the answers do to the card.
    struct Status: Sendable, Equatable {
        /// Whether the card is dismissed: the latest answer is "Not really", at the current confidence.
        let isDismissed: Bool
        /// Whether the card asks "Feel right?": nothing has been answered at the current confidence.
        let asksForFeedback: Bool
        /// The latest "Not really", at any confidence, or `nil` if there's none.
        let lastDisagreement: InsightFeedback?
    }

    /// Returns what `answers` do to a finding at `confidence`.
    ///
    /// - Parameters:
    ///   - confidence: The current finding's confidence.
    ///   - answers: Every answer stored, in any order.
    func status(for confidence: SleepPattern.Confidence, answers: [InsightFeedback]) -> Status {
        let latest = answers.max { $0.answeredAt < $1.answeredAt }
        let answeredNow = latest?.confidence == confidence
        return Status(
            isDismissed: answeredNow && latest?.answer == .disagree,
            asksForFeedback: !answeredNow,
            lastDisagreement: answers.filter { $0.answer == .disagree }.max { $0.answeredAt < $1.answeredAt })
    }
}
