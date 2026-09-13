//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelDataSource
//

/// Wraps the on-device language model.
///
/// An implementation is the only code that touches the Foundation Models framework (constitution Article I.14). This
/// protocol doesn't import it, so the repository and its fakes don't either. The Language Model article lists its
/// requirements, LMSRC-1 to LMSRC-8.
protocol LanguageModelDataSource: Sendable {
    /// Reads whether the model can be used now.
    ///
    /// The framework doesn't announce changes, so the repository calls this again at each whole minute.
    func availability() -> LanguageModelAvailability

    /// Answers one instruction in a new session, with the tools its origin allows, then discards the session.
    ///
    /// - Parameter instruction: The prompt, and where it came from.
    /// - Returns: The model's response.
    /// - Throws: The model's error if it couldn't respond.
    func respond(to instruction: LanguageModelInstruction) async throws -> String

    /// Writes the Insights tab's first finding in a new session with no tools, from a prompt that gives the facts, then
    /// discards the session.
    ///
    /// - Parameter request: The finding to put into words, and the one the user last disagreed with.
    /// - Returns: The insight, and the facts its prompt gave, for the number check.
    /// - Throws: The model's error if it couldn't write the insight.
    func writeInsight(_ request: InsightRequest) async throws -> WrittenInsight
}

/// An insight the model wrote, and the facts its prompt gave, which the repository checks its numbers against.
struct WrittenInsight: Sendable, Equatable {
    /// The insight.
    let insight: Insight
    /// The facts the prompt gave the model.
    let facts: String
}
