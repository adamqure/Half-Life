//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life GeneratedInsight
//

import FoundationModels

/// The Insights tab's first finding, as the language model writes it.
///
/// It mirrors ``Insight``, which can't be `@Generable` because Domain doesn't import FoundationModels (LMSRC-6). Its
/// guides ask for the headline the facts give, in the user's language, and a sentence of at most 25 words on how the
/// nights support it (LMSRC-9). The rules write the headline for the finding's own direction, so the model never
/// chooses one.
@Generable(description: "The one finding on the user's Insights card.")
struct GeneratedInsight {
    /// The facts' headline, in the user's language.
    @Guide(description: "The facts' headline, in the user's language.")
    let headline: String
    /// One sentence, of at most 25 words, on how the nights in the facts support the headline.
    @Guide(
        description: """
            One sentence of at most 25 words that says how the nights in the facts support the headline, with the \
            confidence words.
            """)
    let sentence: String

    /// The insight this mirrors.
    var insight: Insight {
        Insight(headline: headline, sentence: sentence)
    }
}
