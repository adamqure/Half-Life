//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RespondToInstructionUseCase
//

/// Asks the on-device language model to answer one instruction.
///
/// Each instruction gets a session of its own. An App Intent's instruction can log a drink; the app's can only read.
/// See RESPOND-1 in the Language Model article.
struct RespondToInstructionUseCase: UseCase {
    /// The repository that passes the instruction to the model.
    let repository: any LanguageModelRepository

    /// Answers the instruction.
    ///
    /// - Parameter input: The prompt, and where it came from.
    /// - Returns: The model's response.
    /// - Throws: ``LanguageModelError/unavailable`` while the model is unavailable, or the model's error.
    func execute(_ input: LanguageModelInstruction) async throws -> String {
        try await repository.respond(to: input)
    }
}
