//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveCutoffWarningUseCase
//

import Foundation

/// Streams the drink composer's warning: why the chosen drink, at the time chosen, breaks the caffeine cutoff, or
/// `nil` when it fits.
///
/// ``DrinkComposerFeature`` observes it for each choice. ``CaffeineDecayRepository`` calculates it with
/// ``CaffeineCutoffRule``. See the Caffeine Cutoff article.
nonisolated struct ObserveCutoffWarningUseCase: UseCase {
    /// The drink to check.
    struct Input: Sendable, Equatable {
        /// The drink and quantity chosen.
        let drink: FavouriteDrink
        /// How long before the current time it was consumed.
        let secondsAgo: TimeInterval
        /// The calendar, and so the time zone, the bedtime is a time of day in.
        let calendar: Calendar
    }

    /// The repository that calculates the warning.
    let repository: any CaffeineDecayRepository

    /// Returns a stream of the warning: the one for the current time, then each change.
    ///
    /// - Parameter input: The drink, how long ago, and the calendar.
    func execute(_ input: Input) -> AsyncStream<CutoffWarning?> {
        repository.cutoffWarning(for: input.drink, secondsAgo: input.secondsAgo, in: input.calendar)
    }
}
