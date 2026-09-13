//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveSleepWindowUseCase
//

import Foundation

/// Streams tonight's sleep window: when the caffeine already logged falls to the sleep threshold, and the 90 minutes to
/// fall asleep in.
///
/// The Insights tab's "Best time to sleep tonight" card observes it. ``CaffeineDecayRepository`` calculates it with
/// ``SleepWindowRule``. See the Insights article.
struct ObserveSleepWindowUseCase: UseCase {
    /// The repository that owns the window.
    let repository: any CaffeineDecayRepository

    /// Returns a stream of the window: the one for the current time, then each change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the night and the bedtime are in.
    func execute(_ calendar: Calendar) -> AsyncStream<SleepWindow> {
        repository.sleepWindow(in: calendar)
    }
}
