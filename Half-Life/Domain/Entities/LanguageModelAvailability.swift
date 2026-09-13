//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelAvailability
//

/// Whether the features that use the on-device language model can show.
///
/// It's ``available`` only when the model is ready and supports the user's language. Features don't need the reason
/// it's ``unavailable``, because they hide either way. See the Language Model article.
enum LanguageModelAvailability: Sendable, Equatable {
    /// The model is ready, and supports the user's language.
    case available
    /// The model can't be used: the device isn't eligible, Apple Intelligence is off, the model isn't ready, or it
    /// doesn't support the user's language.
    case unavailable
}
