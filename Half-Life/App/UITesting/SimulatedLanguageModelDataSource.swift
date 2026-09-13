//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SimulatedLanguageModelDataSource
//

import Foundation

/// The language model under a UI test: no model at all, so a test doesn't depend on whether the Mac that runs it has
/// Apple Intelligence.
///
/// It's available only when the UI test asked for it with ``LaunchEnvironmentKey/languageModel``. It answers every
/// instruction with the same sentence, and writes an insight from the facts an insight's prompt gives, so the insight
/// passes the number check. Its words stand in for the model's, which aren't in the String Catalog either. See the
/// Language Model article, SIMLM-1 to SIMLM-3.
struct SimulatedLanguageModelDataSource: LanguageModelDataSource {
    /// Whether the UI test asked for the model.
    let isAvailable: Bool
    /// The calendar the insight's facts are formatted in.
    let calendar: Calendar

    /// Whether the UI test asked for the model (SIMLM-1).
    func availability() -> LanguageModelAvailability {
        isAvailable ? .available : .unavailable
    }

    /// Answers with the same sentence, whatever the instruction (SIMLM-3).
    func respond(to instruction: LanguageModelInstruction) async throws -> String {
        "This is the simulated language model's answer."
    }

    /// Writes an insight whose sentence is the facts' line about time asleep (SIMLM-2).
    func writeInsight(_ request: InsightRequest) async throws -> WrittenInsight {
        let facts = InsightFacts(pattern: request.pattern, format: LanguageModelFormat(calendar: calendar)).text
        let timeAsleep = facts.split(separator: "\n").first { $0.hasPrefix("Time asleep:") }.map(String.init) ?? facts
        let insight = Insight(headline: "A pattern in your nights", sentence: timeAsleep)
        return WrittenInsight(insight: insight, facts: facts)
    }
}
