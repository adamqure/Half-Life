//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightLanguageModelTests
//

import Foundation
import FoundationModels
import Testing

@testable import Half_Life

/// Checks how the language model writes the Insights tab's first card, against LMFACT-1, LMFACT-2, and LMSRC-4 to
/// LMSRC-7 in the Language Model article. No test asks the model for a response. Days are in New York, in the `en_US`
/// locale, and the finding's 30 days run from August 14 to September 12, 2026.
struct InsightLanguageModelTests {

    static func format() throws -> LanguageModelFormat {
        LanguageModelFormat(calendar: try LanguageModelFormatTests.calendar("America/New_York"))
    }

    /// Midnight at the start of the day in 2026, in New York.
    static func midnight(month: Int, day: Int) throws -> Date {
        try #require(
            LanguageModelFormatTests.calendar("America/New_York").date(
                from: DateComponents(year: 2026, month: month, day: day)))
    }

    /// A finding over the 30 days from August 14, with `over` and `under` nights either side of `threshold` mg.
    static func pattern(
        over: Int = 6, under: Int = 17, threshold: Double = 40, direction: SleepPattern.Direction = .shorter,
        confidence: SleepPattern.Confidence = .earlySign
    ) throws -> SleepPattern {
        SleepPattern(
            period: DateInterval(start: try midnight(month: 8, day: 14), end: try midnight(month: 9, day: 13)),
            days: 30, nightsOver: over, nightsUnder: under,
            threshold: try #require(SleepThreshold(milligrams: threshold)), direction: direction,
            confidence: confidence)
    }

    /// The facts an insight's prompt gives the model for `pattern`.
    static func facts(_ pattern: SleepPattern) throws -> String {
        InsightFacts(pattern: pattern, format: try format()).text
    }

    // MARK: - LMFACT-1: the facts report the finding, with the direction only

    @Test func theFactsReportTheFindingWithEveryNumberFormatted() throws {
        #expect(
            try Self.facts(try Self.pattern()) == """
                Period: the last 30 days, Aug 14 to Sep 12.
                Caffeine when you fell asleep: over 40 mg on 6 nights, 40 mg or under on 17 nights.
                Nights counted: 23.
                Time asleep: shorter on the nights over 40 mg than on the others.
                Headline: You get more sleep at 40 mg or less.
                Confidence: an early sign.
                7 nights aren't counted: no sleep was recorded, or no drinks were logged before them yet.
                """)
    }

    // MARK: - LMFACT-2: each direction and confidence has its words, and a count of one is singular

    @Test func theFactsWordEachDirectionAndConfidence() throws {
        let longer = try Self.facts(try Self.pattern(threshold: 55, direction: .longer, confidence: .consistent))
        let same = try Self.facts(try Self.pattern(direction: .aboutTheSame, confidence: .tooFew))

        #expect(longer.contains("Time asleep: longer on the nights over 55 mg than on the others.\n"))
        #expect(longer.contains("Headline: You get more sleep above 55 mg.\n"))
        #expect(longer.contains("Confidence: consistent so far.\n"))
        #expect(same.contains("Time asleep: about the same on the nights over 40 mg as on the others.\n"))
        #expect(same.contains("Headline: Your sleep is about the same either side of 40 mg.\n"))
        #expect(same.contains("Confidence: too few nights to say anything yet.\n"))
    }

    @Test func theFactsLeaveOutUncountedNightsWhenThereAreNone() throws {
        let facts = try Self.facts(try Self.pattern(over: 13, under: 17))

        // "Nights counted" stays. Only the line about nights that aren't counted goes.
        #expect(!facts.contains("isn't counted"))
        #expect(!facts.contains("aren't counted"))
        #expect(facts.hasSuffix("Confidence: an early sign."))
    }

    @Test func aCountOfOneIsSingular() throws {
        let facts = try Self.facts(try Self.pattern(over: 1, under: 28))

        #expect(facts.contains("over 40 mg on 1 night, 40 mg or under on 28 nights."))
        #expect(
            facts.hasSuffix("1 night isn't counted: no sleep was recorded, or no drinks were logged before it yet."))
    }

    // MARK: - LMSRC-4: an insight's instructions are the standing rules, from the facts, then the insight rules

    /// The standing rules for an insight's session, which take every number from the facts in the prompt, because
    /// the session has no tools.
    static let insightStandingRules = [
        "You write short answers for Half-Life, an app that shows how much caffeine is in the user's body and when "
            + "it wears off.",
        "Get every number from the facts. Never calculate, estimate, or invent one.",
        "Repeat amounts and days exactly as the facts give them.",
        "If the facts say something isn't available, say so plainly.",
        "Don't diagnose, and don't give medical advice.",
        "Answer in three sentences or fewer.",
        "Answer in French.",
    ]

    /// The insight rules the owner approved on 2026-09-13, in order, reworded the same day for facts in the prompt,
    /// and for a headline the rules write, with a sentence on how the nights support it.
    static let insightRules = [
        "You're writing the one finding on the user's Insights card, from the facts in the prompt.",
        "Use the facts' headline as the headline, in the user's language.",
        "Write one sentence of at most 25 words that says how the nights in the facts support the headline.",
        "Use the facts' confidence words exactly: \"an early sign\" or \"consistent so far\".",
        "Describe a pattern in the user's nights. Never say caffeine caused, cost, or took away sleep, and never say "
            + "how much sleep the user lost.",
        "Don't give advice, and don't tell the user what to do.",
        "If the user disagreed with an earlier finding, take a different approach from that one.",
    ]

    @Test func anInsightsInstructionsAreTheStandingRulesFromTheFactsThenTheInsightRules() {
        let text = LanguageModelInstructions.insightText(locale: Locale(identifier: "fr_FR"))

        #expect(text == (Self.insightStandingRules + Self.insightRules).joined(separator: "\n"))
    }

    @Test func anInsightsInstructionsNeverMentionATool() {
        #expect(!LanguageModelInstructions.insightText(locale: Locale(identifier: "en_US")).contains("tool"))
    }

    // MARK: - LMSRC-5: the prompt, with the facts, and the finding the user last disagreed with

    @Test func thePromptAsksForTheHeadlineAndHowTheDataSupportsIt() {
        #expect(
            LanguageModelInstructions.insightPrompt(facts: "Nights counted: 23.", disagreement: nil) == """
                Write today's finding for the user's Insights card: the facts' headline, and one sentence that says \
                how the data supports it.

                The facts:
                Nights counted: 23.
                """)
    }

    @Test func afterANotReallyThePromptAsksForADifferentApproach() {
        let disagreement = InsightFeedback(
            answer: .disagree, confidence: .earlySign, headline: "Shorter nights with late caffeine",
            sentence: "Your 6 nights over 40 mg were shorter than the others.",
            answeredAt: Date(timeIntervalSinceReferenceDate: 0))

        #expect(
            LanguageModelInstructions.insightPrompt(facts: "Nights counted: 23.", disagreement: disagreement) == """
                Write today's finding for the user's Insights card: the facts' headline, and one sentence that says \
                how the data supports it.

                The facts:
                Nights counted: 23.

                The user disagreed with this earlier finding:
                Headline: "Shorter nights with late caffeine"
                Sentence: "Your 6 nights over 40 mg were shorter than the others."
                Take a different approach from the one in that finding.
                """)
    }

    // MARK: - LMSRC-6: an insight's session has no tools, its facts are the request's, and its answer mirrors one

    @Test func anInsightsSessionHasNoToolsAndTheInsightInstructions() throws {
        let transcript = try LanguageModelDataSourceTests.dataSource().insightSession().transcript
        guard case let .instructions(instructions) = try #require(transcript.first) else {
            Issue.record("The session's transcript doesn't start with its instructions.")
            return
        }
        let text = instructions.segments.compactMap { segment -> String? in
            guard case let .text(text) = segment else { return nil }
            return text.content
        }

        #expect(instructions.toolDefinitions.isEmpty)
        #expect(text == [LanguageModelInstructions.insightText(locale: Locale(identifier: "en_US"))])
    }

    @Test func anInsightsFactsAreTheRequestsFinding() throws {
        let request = InsightRequest(pattern: try Self.pattern(), disagreement: nil)

        #expect(try LanguageModelDataSourceTests.dataSource().insightFacts(for: request) == Self.facts(request.pattern))
    }

    @Test func theGeneratedAnswerMirrorsAnInsight() {
        #expect(GeneratedInsight(headline: "A", sentence: "B.").insight == Insight(headline: "A", sentence: "B."))
    }

    // MARK: - LMSRC-9: the guides ask for the facts' headline, and a sentence on how the nights support it

    @Test func theGuidesAskForTheFactsHeadlineAndHowTheNightsSupportIt() throws {
        let json = try JSONEncoder().encode(GeneratedInsight.generationSchema)
        let schema = try #require(String(bytes: json, encoding: .utf8))

        #expect(schema.contains("The facts' headline, in the user's language."))
        #expect(
            schema.contains(
                "One sentence of at most 25 words that says how the nights in the facts support the headline, with "
                    + "the confidence words."))
    }

    // MARK: - LMSRC-7: an insight's answer is capped at 150 tokens

    @Test func anInsightsAnswerIsCappedAt150Tokens() {
        #expect(FoundationModelLanguageModelDataSource.insightOptions.maximumResponseTokens == 150)
    }
}
