//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelRepository
//

/// The source of truth for whether the on-device language model can be used, and the way to ask it for text.
///
/// An implementation reads the availability from the language model data source, and passes instructions to it. It
/// keeps nothing from an instruction or its response. The Language Model article lists its requirements, LMREPO-1 to
/// LMREPO-5.
protocol LanguageModelRepository: Sendable {
    /// Streams the model's availability: the current one as soon as it's subscribed to, then each change.
    ///
    /// The model doesn't announce changes, so an implementation re-reads the availability at each whole minute.
    func availability() -> AsyncStream<LanguageModelAvailability>

    /// Answers one instruction in a session of its own.
    ///
    /// The response is returned rather than published, because the repository doesn't keep it.
    ///
    /// - Parameter instruction: The prompt, and where it came from.
    /// - Returns: The model's response.
    /// - Throws: ``LanguageModelError/unavailable`` while the model is unavailable, or the model's error if it
    ///   couldn't respond.
    func respond(to instruction: LanguageModelInstruction) async throws -> String

    /// Writes the Insights tab's first finding in a session of its own, and keeps it only if every number in it is one
    /// the finding gave.
    ///
    /// The insight is returned rather than published, because the repository doesn't keep it.
    ///
    /// - Parameter request: The finding to put into words, and the one the user last disagreed with.
    /// - Returns: The insight.
    /// - Throws: ``LanguageModelError/unavailable`` while the model is unavailable, ``LanguageModelError/ungrounded``
    ///   when the insight holds a number the finding didn't give, or the model's error if it couldn't write one.
    func writeInsight(_ request: InsightRequest) async throws -> Insight
}
