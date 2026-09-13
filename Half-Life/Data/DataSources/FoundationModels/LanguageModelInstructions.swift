//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelInstructions
//

import Foundation

/// The standing rules every language model session starts with (LMSRC-3).
///
/// They're prompt text for the model, not text the user sees, so they're written here in English rather than in the
/// String Catalog. The model's answer is what the user sees, and the rules ask for the user's language.
enum LanguageModelInstructions {
    /// The instructions for a session.
    ///
    /// - Parameters:
    ///   - origin: Where the session's instruction came from. Only an App Intent's session is told how to log drinks.
    ///   - locale: The user's locale, whose language the model answers in.
    static func text(for origin: LanguageModelInstruction.Origin, locale: Locale) -> String {
        var rules = standingRules(from: .tools, locale: locale)
        if origin == .appIntent {
            rules.append("Log a drink only when the user says they drank it.")
        }
        return rules.joined(separator: "\n")
    }

    /// The instructions for a session that writes the Insights tab's first finding: the standing rules, taking every
    /// number from the facts in the prompt, because the session has no tools, then the insight rules (LMSRC-4).
    ///
    /// - Parameter locale: The user's locale, whose language the model answers in.
    static func insightText(locale: Locale) -> String {
        (standingRules(from: .facts, locale: locale) + insightRules).joined(separator: "\n")
    }

    /// The prompt for the Insights tab's first finding, with its facts (LMSRC-5).
    ///
    /// After a "Not really", it adds the finding the user disagreed with, and asks for a different approach from it,
    /// so the model learns what kind of finding the user doesn't like.
    ///
    /// - Parameters:
    ///   - facts: The finding's facts, from ``InsightFacts``.
    ///   - disagreement: The finding the user last answered "Not really" to, or `nil` if there's none.
    static func insightPrompt(facts: String, disagreement: InsightFeedback?) -> String {
        let prompt = """
            Write today's finding for the user's Insights card: the facts' headline, and one sentence that says \
            how the data supports it.

            The facts:
            \(facts)
            """
        guard let disagreement else { return prompt }
        return """
            \(prompt)

            The user disagreed with this earlier finding:
            Headline: "\(disagreement.headline)"
            Sentence: "\(disagreement.sentence)"
            Take a different approach from the one in that finding.
            """
    }

    /// Where a session's numbers come from.
    private enum Source {
        /// The session's tools.
        case tools
        /// The facts in the prompt, for a session with no tools.
        case facts
    }

    /// The rules every session starts with, taking every number from `source`.
    private static func standingRules(from source: Source, locale: Locale) -> [String] {
        let sourcing: [String] =
            switch source {
            case .tools: [
                "Get every number, time, and drink from a tool. Never calculate, estimate, or invent one.",
                "Repeat amounts and times exactly as the tools give them.",
                "If a tool says something isn't available, say so plainly.",
            ]
            case .facts: [
                "Get every number from the facts. Never calculate, estimate, or invent one.",
                "Repeat amounts and days exactly as the facts give them.",
                "If the facts say something isn't available, say so plainly.",
            ]
            }
        let intro =
            "You write short answers for Half-Life, an app that shows how much caffeine is in the user's body and when "
            + "it wears off."
        return [intro] + sourcing + [
            "Don't diagnose, and don't give medical advice.",
            "Answer in three sentences or fewer.",
            "Answer in \(languageName(for: locale)).",
        ]
    }

    /// The rules for the Insights tab's first finding, which the owner approved on 2026-09-13. The same day, the
    /// owner moved the facts from the `compareCaffeineTiming` tool into the prompt, so the rules name the facts, and
    /// asked for a headline that says what the finding means, with a sentence on how the data supports it. The model
    /// refused twice while it was asked what the finding meant for the user's sleep, so the facts carry a headline the
    /// rules write, and the model only says how the nights support it.
    private static let insightRules = [
        "You're writing the one finding on the user's Insights card, from the facts in the prompt.",
        "Use the facts' headline as the headline, in the user's language.",
        "Write one sentence of at most 25 words that says how the nights in the facts support the headline.",
        "Use the facts' confidence words exactly: \"an early sign\" or \"consistent so far\".",
        "Describe a pattern in the user's nights. Never say caffeine caused, cost, or took away sleep, and never say "
            + "how much sleep the user lost.",
        "Don't give advice, and don't tell the user what to do.",
        "If the user disagreed with an earlier finding, take a different approach from that one.",
    ]

    /// The English name of the locale's language, such as "French", for the rule that names it.
    private static func languageName(for locale: Locale) -> String {
        guard let code = locale.language.languageCode?.identifier,
            let name = Locale(identifier: "en").localizedString(forLanguageCode: code)
        else {
            return "the user's language"
        }
        return name
    }
}
