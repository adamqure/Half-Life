//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveDrinkLogDayUseCase
//

import Foundation

/// Streams one calendar day of the drink log, its drinks and their caffeine, starting with the day as it is now.
///
/// The Today screen's history card observes it for the day it shows. ``DrinkLogRepository`` picks out the day with
/// ``DrinkLogDayRule``. See the Today Screen article.
struct ObserveDrinkLogDayUseCase: UseCase {
    /// The day to observe.
    struct Input: Sendable, Equatable {
        /// A moment in the day.
        let date: Date
        /// The calendar, and so the time zone, that defines the day.
        let calendar: Calendar
    }

    /// The repository whose drinks the day comes from.
    let repository: any DrinkLogRepository

    /// Returns a stream of the day: as it is now, then each change to it.
    ///
    /// - Parameter input: The day to observe.
    func execute(_ input: Input) -> AsyncStream<DrinkLogDay> {
        repository.day(containing: input.date, in: input.calendar)
    }
}
