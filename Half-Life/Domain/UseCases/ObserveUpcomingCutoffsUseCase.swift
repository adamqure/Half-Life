//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveUpcomingCutoffsUseCase
//

import Foundation

/// Streams the cutoffs for the next several bedtimes, tonight's first.
///
/// ``CutoffReminderFeature`` observes them, to schedule a reminder at each. ``CaffeineDecayRepository`` calculates
/// them with ``CaffeineCutoffRule``. See the Cutoff Reminder article.
nonisolated struct ObserveUpcomingCutoffsUseCase: UseCase {
    /// Which cutoffs to stream.
    struct Input: Sendable {
        /// How many bedtimes to calculate a cutoff for, tonight's first.
        let nights: Int
        /// The calendar, and so the time zone, the bedtime is a time of day in.
        let calendar: Calendar
    }

    /// The repository that owns the cutoffs.
    let repository: any CaffeineDecayRepository

    /// Returns a stream of the upcoming cutoffs: those for the current time, then each change.
    ///
    /// - Parameter input: How many nights, and the calendar.
    func execute(_ input: Input) -> AsyncStream<[CaffeineCutoff]> {
        repository.upcomingCutoffs(nights: input.nights, in: input.calendar)
    }
}
