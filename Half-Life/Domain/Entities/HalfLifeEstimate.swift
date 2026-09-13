//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeEstimate
//

import Foundation

/// The user's personal half-life: the survey's starting half-life, updated with their own nights.
///
/// ``HalfLifeEstimationRule`` makes it. When the nights can't say anything, because there aren't enough of them or
/// they don't vary, it's the starting half-life with the starting range. A half-life is a health value, so no part of
/// an estimate is ever logged (constitution Article XI.6). See the Half-Life Estimator article.
struct HalfLifeEstimate: Sendable, Equatable {
    /// The half-life the decay model uses: the middle of the estimate, as likely to be above as below.
    let halfLife: CaffeineHalfLife
    /// The bottom of the range the half-life is 80% likely to be in. Never below 3 hours.
    let lowerBound: CaffeineHalfLife
    /// The top of the range the half-life is 80% likely to be in. Never above 40 hours.
    let upperBound: CaffeineHalfLife
    /// The starting half-life the survey gave, which the estimate started from.
    let prior: CaffeineHalfLife
    /// How many nights the estimate used. It's 0 when there weren't enough, and the estimate is the prior.
    let nightsUsed: Int
    /// When the estimate was calculated.
    let calculatedAt: Date
}
