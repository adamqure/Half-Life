//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WriteInsightUseCase
//

/// Asks the on-device language model to put the Insights tab's first finding into words.
///
/// The request carries the finding the card holds, and the one the user last disagreed with. See WRITE-1 in the
/// Language Model article.
struct WriteInsightUseCase: UseCase {
    /// The repository that passes the request to the model, and checks the answer's numbers.
    let repository: any LanguageModelRepository

    /// Writes the insight.
    ///
    /// - Parameter input: The finding to put into words, and the one the user last disagreed with.
    /// - Returns: The insight.
    /// - Throws: ``LanguageModelError/unavailable`` while the model is unavailable, ``LanguageModelError/ungrounded``
    ///   when the answer held a number the finding didn't give, or the model's error.
    func execute(_ input: InsightRequest) async throws -> Insight {
        try await repository.writeInsight(input)
    }
}
