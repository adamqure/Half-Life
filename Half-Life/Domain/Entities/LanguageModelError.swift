//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelError
//

/// Why the on-device language model couldn't answer an instruction.
enum LanguageModelError: Error, Equatable {
    /// The model is unavailable, so the instruction never reached it. A feature that uses the model hides while it's
    /// unavailable, so this means the model became unavailable after the feature showed.
    case unavailable
    /// The model's answer held a number its tools didn't give, so it was discarded. A feature shows nothing, rather
    /// than a number the rules didn't work out.
    case ungrounded
}
