//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RecommendedSleep
//

import Foundation

/// The nightly sleep recommended for a user's age, from the National Sleep Foundation's consensus.
///
/// ``SleepNeedRule`` chooses one. See the Onboarding article.
nonisolated struct RecommendedSleep: Sendable, Equatable {
    /// 8 to 10 hours, for ages 13 to 17.
    static let teen = RecommendedSleep(minimumHours: 8, maximumHours: 10)
    /// 7 to 9 hours, for ages 18 to 64, and when the age isn't known.
    static let adult = RecommendedSleep(minimumHours: 7, maximumHours: 9)
    /// 7 to 8 hours, for ages 65 and over.
    static let olderAdult = RecommendedSleep(minimumHours: 7, maximumHours: 8)

    /// The least recommended, in seconds.
    let minimumSeconds: TimeInterval
    /// The most recommended, in seconds.
    let maximumSeconds: TimeInterval

    /// Creates a range from whole or fractional hours.
    ///
    /// - Parameters:
    ///   - minimumHours: The least recommended, in hours.
    ///   - maximumHours: The most recommended, in hours.
    init(minimumHours: Double, maximumHours: Double) {
        minimumSeconds = minimumHours * 3_600
        maximumSeconds = maximumHours * 3_600
    }
}
