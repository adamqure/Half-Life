//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogRepository
//

import Foundation

/// The source of truth for every drink the user has logged.
///
/// An implementation stores drinks through the drink data source, which it shares with ``CaffeineDecayRepository``.
/// It publishes what the data source holds: after each change the data source signals, it re-reads the drinks and
/// publishes them. It also executes ``DailyCaffeineIntakeRule`` to publish the caffeine logged today, and
/// ``DrinkLogDayRule`` to publish any one day of the log. The Drink Composer article lists its requirements, DLOG-1 to
/// DLOG-4, and the Today Screen article adds DLOG-5 to DLOG-9, DAYLOG-1 to DAYLOG-3, and DELETE-1 to DELETE-3.
protocol DrinkLogRepository: Sendable {
    /// Streams every logged drink, oldest first, starting with the current set.
    ///
    /// Each new subscriber immediately receives every logged drink. After that, every subscriber receives the
    /// updated set whenever the drink data source signals a change.
    func loggedDrinks() -> AsyncStream<[LoggedDrink]>

    /// Streams the caffeine logged on the current calendar day, starting with the current total.
    ///
    /// Each new subscriber immediately receives the current day's intake. After that, a subscriber receives a new
    /// intake only when it changes: after the drink data source signals a change that alters the day's total, and at
    /// the first minute of each new day.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, that defines the day.
    func intakeToday(in calendar: Calendar) -> AsyncStream<DailyCaffeineIntake>

    /// Streams one calendar day of the log, its drinks and their caffeine, starting with the day as it is now.
    ///
    /// Each new subscriber immediately receives the day. After that, a subscriber receives a new day only when a
    /// change the drink data source signals alters it. The day is fixed, so it never follows the clock.
    ///
    /// - Parameters:
    ///   - date: A moment in the day.
    ///   - calendar: The calendar, and so the time zone, that defines the day.
    func day(containing date: Date, in calendar: Calendar) -> AsyncStream<DrinkLogDay>

    /// Stores a drink. The updated set is published when the data source signals the change.
    ///
    /// The repository first executes ``DrinkLogRule`` with the current time.
    ///
    /// - Parameter drink: The drink to store.
    /// - Throws: A ``DrinkLogRule/Violation`` if the drink can't be logged, or an error if it couldn't be stored.
    func log(_ drink: LoggedDrink) async throws

    /// Deletes a drink. Every stream is updated when the data source signals the change, and so is
    /// ``CaffeineDecayRepository``, which shares the data source.
    ///
    /// - Parameter id: The identifier of the drink to delete.
    /// - Throws: An error if the deletion couldn't be stored. Nothing is published then.
    func delete(_ id: LoggedDrink.ID) async throws
}
