//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelInstruction
//

/// One instruction for the on-device language model: a prompt, and where it came from.
///
/// Each instruction gets its own session, which is discarded with its response. Half-Life isn't a chatbot, so nothing
/// carries from one instruction to the next. See the Language Model article.
struct LanguageModelInstruction: Sendable, Equatable {
    /// Where an instruction came from, which decides the tools its session gets.
    enum Origin: Sendable, Equatable {
        /// The words the user sent through an App Intent. Only these sessions can log a drink.
        case appIntent
        /// Text the app wrote, such as a request for an insight. These sessions can only read.
        case app
    }

    /// What the model is asked.
    let prompt: String
    /// Where the instruction came from.
    let origin: Origin
}
