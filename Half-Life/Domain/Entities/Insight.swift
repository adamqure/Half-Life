//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Insight
//

/// The Insights tab's first finding, as the on-device language model put it into words.
///
/// It's written from caffeine and sleep, which are health data, so it's never logged (constitution Article XI.6). See
/// the Insights article.
struct Insight: Sendable, Equatable {
    /// The headline, of at most 8 words.
    let headline: String
    /// One sentence, of at most 25 words.
    let sentence: String
}
