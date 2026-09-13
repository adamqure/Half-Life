//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightRequest
//

/// A request to the on-device language model for the Insights tab's first finding.
///
/// It carries the finding the card holds, so the model's words can't disagree with the card, and the finding the user
/// last disagreed with, so the model takes a different approach from it. It's health data, so it's never logged
/// (constitution Article XI.6). See the Insights article.
struct InsightRequest: Sendable, Equatable {
    /// The finding to put into words.
    let pattern: SleepPattern
    /// The finding the user last answered "Not really" to, or `nil` if there's none.
    let disagreement: InsightFeedback?
}
