//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveDrinkLogWeekUseCase
//

import Foundation

/// Streams the 7 days before today, yesterday last, each with its drinks and their caffeine.
///
/// The Insights tab's "The last 7 days" card observes it. It leaves out today, because today's night hasn't happened
/// yet. ``DrinkLogRepository`` calculates the 8 days to today with ``DrinkLogDayRule``, and this drops today, and sends
/// the 7 only when they change. It holds no state between calls. See WEEKUSE-1 in the Insights article.
struct ObserveDrinkLogWeekUseCase: UseCase {
    /// How many days the week holds, all before today.
    static let dayCount = 7

    /// The repository that owns the drink log.
    let repository: any DrinkLogRepository

    /// Returns a stream of the 7 days before today: the current ones, then each change. A change to today alone sends
    /// nothing.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, that defines the days.
    func execute(_ calendar: Calendar) -> AsyncStream<[DrinkLogDay]> {
        let days = repository.recentDays(Self.dayCount + 1, in: calendar)
        return AsyncStream { continuation in
            let task = Task {
                var lastSent: [DrinkLogDay]?
                for await toToday in days {
                    let week = Array(toToday.dropLast())
                    guard week != lastSent else { continue }
                    lastSent = week
                    continuation.yield(week)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
