//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveTimeOfDayUseCase
//

import Foundation

/// Streams the time of day: the current minute and the part of the day it falls in, then each new minute.
///
/// It executes ``DayPeriodRule`` on each minute that ``CurrentTimeRepository`` streams. Use cases that execute a
/// business rule are exceptions the owner approved: this one over a second clock repository, and
/// ``ObserveRestingHeartRateComparisonUseCase`` and ``ObserveStepsComparisonUseCase``, which each combine two
/// repositories' streams. See the Today Screen article.
nonisolated struct ObserveTimeOfDayUseCase: UseCase {
    /// The repository that streams the current time.
    let currentTime: any CurrentTimeRepository

    /// Returns a stream of the time of day, starting with the current minute.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, to find each minute's day period in.
    func execute(_ calendar: Calendar) -> AsyncStream<TimeOfDay> {
        let minutes = currentTime.currentTime()
        let rule = DayPeriodRule()
        return AsyncStream { continuation in
            let task = Task {
                for await date in minutes {
                    continuation.yield(TimeOfDay(date: date, period: rule.period(at: date, calendar: calendar)))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
