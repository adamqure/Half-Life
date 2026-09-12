//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineDecayRepository
//

import Foundation

/// The source of truth for the active caffeine curve and the caffeine status.
///
/// An implementation reads the drinks that aren't marked negligible from the drink log data source, reads the
/// half-life and the absorption rate from their data sources, and executes ``CaffeineDecayRule`` to calculate the
/// curve. It has the
/// drink log data source mark the intakes the rule finds negligible, so later reads skip them. It also reads the
/// bedtime from the bedtime data source, and executes ``CaffeineStatusRule`` to calculate the status. Drinks reach
/// it only through the data source, which signals when they change. The Caffeine Decay Model article lists its
/// requirements, REPO-1 to REPO-10.
///
/// It isn't marked `nonisolated`: an actor that conforms to a `nonisolated` protocol in the same module inherits
/// `nonisolated`, which an actor can't be (constitution Article IV.1).
protocol CaffeineDecayRepository: Sendable {
    /// Streams the active curve.
    ///
    /// Each new subscriber immediately receives a curve calculated for the current time. After that, every
    /// subscriber receives a new curve whenever the data the curve comes from changes. The repository never
    /// recalculates the curve on a timer.
    func curve() -> AsyncStream<[CaffeineLevel]>

    /// Streams the caffeine status: the level now, and the decay card's two tips.
    ///
    /// Each new subscriber immediately receives a status calculated for the current time. After that, every
    /// subscriber receives a new status at every whole minute, and whenever the data the status comes from changes.
    /// The status is the one thing the repository recalculates on a timer, because it's about the current time.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func status(in calendar: Calendar) -> AsyncStream<CaffeineStatus>

    /// Streams the cutoff: the latest time the user's usual drink can be drunk and still leave no more than the sleep
    /// threshold in the body at bedtime.
    ///
    /// Each new subscriber immediately receives the cutoff for the current time. After that, a subscriber receives a
    /// new cutoff only when it changes: after a change to the data it comes from, or at a minute when the cutoff
    /// passes. The implementation executes ``CaffeineCutoffRule``, for the first favourite ``FavouriteDrinksRule``
    /// finds in the drink log. See the Caffeine Cutoff article.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func cutoff(in calendar: Calendar) -> AsyncStream<CaffeineCutoff>
}
