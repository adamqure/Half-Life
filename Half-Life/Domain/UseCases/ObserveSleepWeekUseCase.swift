//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveSleepWeekUseCase
//

import Foundation

/// Streams the sleep that followed each of the 7 days before today, yesterday's last, from Apple Health or the demo.
///
/// The Insights tab's "The last 7 days" card observes it. ``HealthDataRepository`` finds the nights after the 8 days to
/// today with ``SleepHistoryRule``, and this drops tonight's, which hasn't happened, and sends the 7 only when they
/// change. It holds no state between calls. See SLEEPUSE-1 in the Insights article.
struct ObserveSleepWeekUseCase: UseCase {
    /// How many days the week holds, all before today.
    static let dayCount = 7

    /// The repository that owns the Health data.
    let repository: any HealthDataRepository

    /// Returns a stream of the nights after the 7 days before today: the current ones, then each change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days and noons define the nights.
    func execute(_ calendar: Calendar) -> AsyncStream<SleepHistory> {
        let histories = repository.sleepHistory(days: Self.dayCount + 1, in: calendar)
        return AsyncStream { continuation in
            let task = Task {
                var lastSent: SleepHistory?
                for await toTonight in histories {
                    let week = SleepHistory(nights: Array(toTonight.nights.dropLast()), isDemo: toTonight.isDemo)
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
