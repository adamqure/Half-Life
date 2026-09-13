//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightCard
//

/// What the Insights tab's first card shows: the finding, whether it asks "Feel right?", the finding the user last
/// disagreed with, and whether the nights are the demo's.
///
/// ``ObserveInsightCardUseCase`` makes it, and sends `nil` instead while the card is hidden. It's derived from caffeine
/// and sleep, which are health data, so no part of it is ever logged (constitution Article XI.6). See the Insights
/// article.
struct InsightCard: Sendable, Equatable {
    /// The finding.
    let pattern: SleepPattern
    /// Whether the card asks "Feel right?": nothing has been answered at the finding's confidence.
    let asksForFeedback: Bool
    /// The latest "Not really", at any confidence, which the next prompt quotes, or `nil` if there's none.
    let disagreement: InsightFeedback?
    /// Whether the nights came from the demo Health data rather than Apple Health.
    let isDemo: Bool
}
