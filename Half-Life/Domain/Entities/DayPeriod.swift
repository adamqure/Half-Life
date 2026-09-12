//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DayPeriod
//

/// The part of the day a greeting is for.
///
/// Each period includes its start and excludes its end. ``DayPeriodRule`` finds the period for a moment. See the
/// Today Screen article.
nonisolated enum DayPeriod: Sendable, Equatable {
    /// From 5:00am until 12:00pm.
    case morning
    /// From 12:00pm until 5:00pm.
    case afternoon
    /// From 5:00pm until 5:00am.
    case evening
}
