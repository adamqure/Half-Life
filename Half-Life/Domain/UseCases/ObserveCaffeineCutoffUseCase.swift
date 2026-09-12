//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveCaffeineCutoffUseCase
//

import Foundation

/// Streams the caffeine cutoff: the latest time the user's usual drink can be drunk and still leave no more than the
/// sleep threshold in the body at bedtime.
///
/// The Today screen's "Last cup" tile observes it. ``CaffeineDecayRepository`` calculates it with
/// ``CaffeineCutoffRule``. See the Caffeine Cutoff article.
struct ObserveCaffeineCutoffUseCase: UseCase {
    /// The repository that owns the cutoff.
    let repository: any CaffeineDecayRepository

    /// Returns a stream of the cutoff: the one for the current time, then each change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func execute(_ calendar: Calendar) -> AsyncStream<CaffeineCutoff> {
        repository.cutoff(in: calendar)
    }
}
