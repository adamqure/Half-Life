//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveCaffeineStatusUseCase
//

import Foundation

/// Streams the caffeine status: the level now and the decay card's two tips.
nonisolated struct ObserveCaffeineStatusUseCase: UseCase {
    /// The repository that owns the status.
    let repository: any CaffeineDecayRepository

    /// Returns a stream of the status: one for the current time, then a new one at every whole minute and after
    /// every change to the drinks.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func execute(_ calendar: Calendar) -> AsyncStream<CaffeineStatus> {
        repository.status(in: calendar)
    }
}
