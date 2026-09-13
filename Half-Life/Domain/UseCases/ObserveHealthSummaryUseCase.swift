//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveHealthSummaryUseCase
//

import Foundation

/// Streams today's Apple Health summary, starting with the current one.
///
/// The Today screen's Apple Health card observes it. ``HealthDataRepository`` reads the data and finds last night with
/// ``LastNightSleepRule``. The Apple Health Card article lists its requirement, HUSE-1.
struct ObserveHealthSummaryUseCase: UseCase {
    /// The repository whose Health data is summarized.
    let repository: any HealthDataRepository

    /// Returns a stream of today's summary: the current one, then each change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days and noons define today and last night.
    func execute(_ calendar: Calendar) -> AsyncStream<HealthSummary> {
        repository.summary(in: calendar)
    }
}
