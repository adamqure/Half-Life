//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveAvailableHealthDataUseCase
//

import Foundation

/// Streams the kinds of Health data that have any data in the last 30 days: the Insights tab's Health data buttons.
///
/// ``HealthDataRepository`` finds them with ``HealthDataAvailabilityRule``. See the Insights article.
struct ObserveAvailableHealthDataUseCase: UseCase {
    /// How many days to look back, today included.
    static let dayCount = 30

    /// The repository that owns the Health data.
    let repository: any HealthDataRepository

    /// Returns a stream of the available kinds: the current set, then each change.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days are looked back over.
    func execute(_ calendar: Calendar) -> AsyncStream<Set<HealthDataKind>> {
        repository.availableKinds(days: Self.dayCount, in: calendar)
    }
}
