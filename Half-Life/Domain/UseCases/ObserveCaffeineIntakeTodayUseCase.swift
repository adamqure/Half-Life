//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveCaffeineIntakeTodayUseCase
//

import Foundation

/// Streams the caffeine logged on the current calendar day, starting with the current total.
///
/// The Today screen's "Today" tile observes it. ``DrinkLogRepository`` totals the day with
/// ``DailyCaffeineIntakeRule``. See the Today Screen article.
struct ObserveCaffeineIntakeTodayUseCase: UseCase {
    /// The repository whose drinks are totalled.
    let repository: any DrinkLogRepository

    /// Returns a stream of today's intake: the current total, then each change, including the new day's at midnight.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, that defines the day.
    func execute(_ calendar: Calendar) -> AsyncStream<DailyCaffeineIntake> {
        repository.intakeToday(in: calendar)
    }
}
