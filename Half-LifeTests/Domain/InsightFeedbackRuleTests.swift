//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightFeedbackRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks what the "Feel right?" answers do to the first card, against FEEDBACK-1 to FEEDBACK-4 in the Insights
/// article. The rule is pure, so its tests need no fakes.
struct InsightFeedbackRuleTests {

    let rule = InsightFeedbackRule()

    static func answer(
        _ answer: InsightFeedback.Answer, _ confidence: SleepPattern.Confidence, minutes: Double
    ) -> InsightFeedback {
        InsightFeedback(
            answer: answer, confidence: confidence, headline: "Headline \(minutes)", sentence: "Sentence \(minutes)",
            answeredAt: Date(timeIntervalSinceReferenceDate: minutes * 60))
    }

    // MARK: - FEEDBACK-1: with no answers, the card shows and asks

    @Test func withNoAnswersTheCardShowsAndAsks() {
        let status = rule.status(for: .earlySign, answers: [])

        #expect(!status.isDismissed)
        #expect(status.asksForFeedback)
        #expect(status.lastDisagreement == nil)
    }

    // MARK: - FEEDBACK-2: "Not really" dismisses the card until the confidence changes

    @Test func notReallyDismissesTheCardUntilTheConfidenceChanges() {
        let answers = [Self.answer(.disagree, .earlySign, minutes: 1)]

        #expect(rule.status(for: .earlySign, answers: answers).isDismissed)
        let changed = rule.status(for: .consistent, answers: answers)
        #expect(!changed.isDismissed)
        #expect(changed.asksForFeedback)
    }

    // MARK: - FEEDBACK-3: "Yes" hides the question until the confidence changes, and the card stays

    @Test func yesHidesTheQuestionUntilTheConfidenceChanges() {
        let answers = [Self.answer(.disagree, .earlySign, minutes: 1), Self.answer(.agree, .earlySign, minutes: 2)]

        let same = rule.status(for: .earlySign, answers: answers)
        #expect(!same.isDismissed)
        #expect(!same.asksForFeedback)
        #expect(rule.status(for: .consistent, answers: answers).asksForFeedback)
    }

    // MARK: - FEEDBACK-4: the prompt's disagreement is the latest "Not really", at any confidence

    @Test func theLastDisagreementIsTheLatestNotReally() {
        let first = Self.answer(.disagree, .earlySign, minutes: 1)
        let latest = Self.answer(.disagree, .consistent, minutes: 3)
        let answers = [latest, first, Self.answer(.agree, .consistent, minutes: 4)]

        #expect(rule.status(for: .earlySign, answers: answers).lastDisagreement == latest)
    }
}
