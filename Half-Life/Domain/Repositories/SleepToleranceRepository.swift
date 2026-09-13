//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepToleranceRepository
//

import Foundation

/// The source of truth for the user's caffeine tolerance, and for the analysis of their nights it comes from.
///
/// It reads the sleep of the last 30 days, from Apple Health or the demo, the drinks, and the decay model's kinetics,
/// executes ``SleepToleranceRule``, stores the tolerance where the decay model reads it as the sleep threshold, and
/// publishes each change (constitution Article I.12). It also publishes each night's caffeine, the one stream every
/// comparison on the Insights tab reads. The Insights article lists its requirements, TOLREPO-1 to TOLREPO-11.
protocol SleepToleranceRepository: Sendable {
    /// Streams the analysis of the nights in the last 30 days: the current one as soon as it's subscribed to, then
    /// each change. It never finishes.
    func analysis() -> AsyncStream<SleepCaffeineAnalysis>

    /// Streams the caffeine in the user when each of the last `days` nights began, judged against the threshold in
    /// use: the current history as soon as it's subscribed to, then each change. It never finishes.
    ///
    /// Every comparison on the Insights tab reads it, so they all split the nights the same way. The implementation
    /// executes ``CaffeineNightRule`` with the onsets ``SleepToleranceRule`` recognises, and the user's bedtime for
    /// the nights without one. See TOLREPO-8 to TOLREPO-11 in the Insights article.
    ///
    /// - Parameters:
    ///   - days: How many nights, the one that followed yesterday last.
    ///   - calendar: The calendar, and so the time zone, the days, the noons, and the bedtime are in.
    func caffeineNights(days: Int, in calendar: Calendar) -> AsyncStream<CaffeineNightHistory>
}
