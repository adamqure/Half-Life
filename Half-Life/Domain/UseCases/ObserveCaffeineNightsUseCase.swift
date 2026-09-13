//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveCaffeineNightsUseCase
//

import Foundation

/// Streams the caffeine in the user when each of the last 31 nights began: the nights every comparison on the
/// Insights tab splits by.
///
/// ``SleepToleranceRepository`` calculates them with ``CaffeineNightRule``. See TOLUSE-3 in the Insights article.
struct ObserveCaffeineNightsUseCase: UseCase {
    /// How many nights: 31, the night before each of the last 30 days and the one before that.
    static let dayCount = 31

    /// The repository that owns the nights.
    let repository: any SleepToleranceRepository

    /// Returns a stream of the nights: the current history, then each change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the days, the noons, and the bedtime are in.
    func execute(_ calendar: Calendar) -> AsyncStream<CaffeineNightHistory> {
        repository.caffeineNights(days: Self.dayCount, in: calendar)
    }
}
